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

    private var timeoutTimer: Timer?

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

        guard
            let adapter = adapters.first(where: { $0.demandId == demand && $0.provider is any GenericDirectDemandProvider }),
            let provider = adapter.provider as? any GenericDirectDemandProvider
        else {
            logLoadingError(error: .unknownAdapter)
            finish()

            return
        }
        setupTimeout()

        let event = DirectDemandWillLoadAuctionEvent(
            adUnit: adUnit
        )
        observer.log(event)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            provider.load(
                pricefloor: adUnit.pricefloor,
                adUnitExtrasDecoder: self.adUnit.extras
            ) { [weak self] result in
                defer { self?.finish() }

                guard let self else { return }

                guard !isCancelled else {
                    Logger.warning("Demand Reqest is canceled due to timeout or cancel event. Break")
                    return
                }

                self.invalidateTimer()

                switch result {
                case .success(let ad):
                    if let price = ad.price, price < auctionConfiguration.pricefloor {
                        let event = DirectDemandLoadingErrorAucitonEvent(adUnit: adUnit, error: .belowPricefloor)
                        observer.log(event)
                        return
                    }
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
    }

    private func logLoadingError(error: MediationError) {
        let event = DirectDemandLoadingErrorAucitonEvent(adUnit: adUnit, error: error)
        observer.log(event)
    }

    override func cancel() {
        super.cancel()
        invalidateTimer()
    }

    func invalidateTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}

extension AuctionOperationRequestDirectDemand: OperationTimeout {
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

extension AuctionOperationRequestDirectDemand: OperationTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }
        observer.log(
            DirectDemandLoadingErrorAucitonEvent(
                adUnit: adUnit,
                error: .fillTimeoutReached
            )
        )

        invalidateTimer()
        finish()
    }
}
