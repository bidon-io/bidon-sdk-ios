//
//  RequestDirectDemandOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationRequestDirectDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperationRequestDemand {

    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    
    let observer: AnyAuctionObserver
    let adapters: [AdapterType]
    let demand: String
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    let adUnit: AdUnitModel
    
    private(set) var bid: BidType?

    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demand = builder.demand
        self.observer = builder.observer
        self.context = builder.context
        self.auctionConfiguration = builder.auctionConfiguration
        self.adUnit = builder.adUnit
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        guard isExecuting else { return }
        
        guard
            let adapter = adapters.first(where: { $0.demandId == demand && $0.provider is any GenericDirectDemandProvider }),
            let provider = adapter.provider as? any GenericDirectDemandProvider
        else {
            logLoadingError(error: .unknownAdapter)
            finish()
            
            return
        }
        
        let event = DirectDemandWillLoadAuctionEvent(
            adUnit: adUnit
        )
        observer.log(event)
        
        setupTimeout()
        
        provider.load(
            pricefloor: auctionConfiguration.pricefloor,
            adUnitExtrasDecoder: adUnit.extras
        ) { [weak self] result in
            guard let self = self else { return }
            defer { self.finish() }
            
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
                    roundPricefloor: self.auctionConfiguration.pricefloor,
                    auctionConfiguration: self.auctionConfiguration
                )
                
                self.bid = bid
                
                let event = DirectDemandDidLoadAuctionEvent(bid: bid)
                self.observer.log(event)
                
            case .failure(let error):
                logLoadingError(error: error)
            }
        }
    }
    
    private func logLoadingError(error: MediationError) {
        let event = DirectDemandLoadingErrorAucitonEvent(adUnit: adUnit, error: error)
        observer.log(event)
    }
}

extension AuctionOperationRequestDirectDemand: TimeoutOperation {
    var timeout: TimeInterval {
        return adUnit.timeoutInSeconds
    }
    
    func setupTimeout() {
        guard isExecuting, timeout > 0 else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.operationTimeoutReached()
        }
    }
    
    func operationTimeoutReached() {
        guard isExecuting else { return }
        observer.log(
            DirectDemandLoadingErrorAucitonEvent(
                adUnit: adUnit,
                error: .fillTimeoutReached
            )
        )
        finish()
        cancel()
    }
}

extension AuctionOperationRequestDirectDemand: AuctionOperationRoundTimeoutHandler {
    
    func timeoutReached() {
        guard isExecuting else { return }
        
        observer.log(
            DirectDemandLoadingErrorAucitonEvent(
                adUnit: adUnit,
                error: .fillTimeoutReached
            )
        )
        finish()
    }
}
