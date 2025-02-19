//
//  AuctionOperationRequestBiddingDemand.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


final class AuctionOperationRequestBiddingDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperationRequestDemand {
    
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    
    let observer: AnyAuctionObserver
    let adapters: [AdapterType]
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    let demand: String
    let adUnit: AdUnitModel
    
    var bid: BidModel<AdTypeContextType.DemandProviderType>?
    
    private let timerLock = NSLock()
    private let cancelLock = NSLock()
    private let finishLock = NSLock()

    private var isFinishedFlag = false
    private var _timeoutTimer: Timer?
    private var timeoutTimer: Timer? {
        get {
            timerLock.lock()
            defer { timerLock.unlock() }
            return _timeoutTimer
        }
        set {
            timerLock.lock()
            _timeoutTimer = newValue
            timerLock.unlock()
        }
    }
    
    
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        self.context = builder.context
        self.demand = builder.demand
        self.adUnit = builder.adUnit
        
        super.init()
    }
    
    override func main() {
        super.main()
                
        guard
            let adapter = adapters.first(where: { $0.demandId == demand && $0.provider is any GenericBiddingDemandProvider }),
            let provider = adapter.provider as? any GenericBiddingDemandProvider
        else {
            logLoadingError(error: .unknownAdapter)
            finish()
            return
        }
        setupTimeout()

        let event = BiddingDemandWillLoadAuctionEvent(
            adUnit: adUnit
        )
        observer.log(event)
        
        provider.load(
            payloadDecoder: adUnit.extras,
            adUnitExtrasDecoder: adUnit.extras
        ) { [weak self] result in
            guard let self else { return }

            cancelLock.lock()
            let cancelled = self.isCancelled
            cancelLock.unlock()

            if cancelled {
                Logger.warning("Demand Request is canceled due to timeout or cancel event. Break")
                return
            }
            
            self.invalidateTimer()
            
            switch result {
            case .success(let ad):
                let bid = BidType(
                    id: UUID().uuidString,
                    impressionId: UUID().uuidString,
                    adType: self.context.adType,
                    adUnit: adUnit,
                    price: ad.price ?? adUnit.pricefloor,
                    ad: ad,
                    provider: adapter.provider,
                    roundPricefloor: adUnit.pricefloor,
                    auctionConfiguration: self.auctionConfiguration
                )
                
                self.bid = bid
                
                let event = BiddingDemandDidLoadAuctionEvent(bid: bid)
                self.observer.log(event)
                
            case .failure(let error):
                logLoadingError(error: error)
            }
            
            self.safeFinish()
        }
    }
    
    private func logLoadingError(error: MediationError) {
        let event = BiddingDemandLoadingErrorAucitonEvent(adUnit: adUnit, error: error)
        observer.log(event)
    }
    
    override func cancel() {
        cancelLock.lock()
        super.cancel()
        cancelLock.unlock()
        invalidateTimer()
    }
    
    private func invalidateTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    private func safeFinish() {
        finishLock.lock()
        if !isFinishedFlag {
            isFinishedFlag = true
            finish()
        }
        finishLock.unlock()
    }
}

extension AuctionOperationRequestBiddingDemand: OperationTimeout {
    var timeout: TimeInterval {
        return adUnit.timeoutInSeconds
    }
    
    func setupTimeout() {
        guard isExecuting, timeout > 0 else { return }

        let timer = Timer(
            timeInterval: timeout,
            repeats: false
        ) { [weak self] _ in
            self?.timeoutReached()
        }
        
        RunLoop.main.add(timer, forMode: .default)
        timeoutTimer = timer
    }
}

extension AuctionOperationRequestBiddingDemand: OperationTimeoutHandler {
    
    func timeoutReached() {
        guard isExecuting else { return }
        
        observer.log(
            BiddingDemandLoadingErrorAucitonEvent(
                adUnit: adUnit, 
                error: .fillTimeoutReached
            )
        )
        
        invalidateTimer()
        finish()
    }
}
