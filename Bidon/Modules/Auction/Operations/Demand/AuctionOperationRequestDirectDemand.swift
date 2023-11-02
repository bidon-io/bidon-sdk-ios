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
    
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var adapters: [AdapterType]!
        private(set) var demands: [String]!
        private(set) var adUnitProvider: AdUnitProvider!
        
        @discardableResult
        func withAdapters(_ adapters: [AdapterType]) -> Self {
            self.adapters = adapters
            return self
        }
        
        @discardableResult
        func withDemands(_ demands: [String]) -> Self {
            self.demands = demands
            return self
        }
        
        @discardableResult
        func withAdUnitProvider(_ adUnitProvider: AdUnitProvider) -> Self {
            self.adUnitProvider = adUnitProvider
            return self
        }
    }
    
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    let demands: [String]
    let adUnitProvider: AdUnitProvider
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    private(set) var bids: [BidType] = []
    
    init(builder: Builder) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.observer = builder.observer
        self.context = builder.context
        self.roundConfiguration = builder.roundConfiguration
        self.auctionConfiguration = builder.auctionConfiguration
        self.adUnitProvider = builder.adUnitProvider
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
        for demandId in demands {
            guard
                let adapter = adapters.first(where: { $0.demandId == demandId }),
                let provider = adapter.provider as? any GenericDirectDemandProvider
            else {
                let event = DemandProviderNotFoundMediationEvent(
                    roundConfiguration: roundConfiguration,
                    demandId: demandId
                )
                
                observer.log(event)
                
                continue
            }
            
            guard let adUnit = adUnitProvider.directAdUnit(for: demandId, pricefloor: pricefloor) else {
                let event = DirectDemandProviderLineItemNotFoundMediationEvent(
                    roundConfiguration: roundConfiguration,
                    adapter: adapter
                )
                
                observer.log(event)
                
                continue
            }
            
            group.enter()
            
            provider.load(
                pricefloor: pricefloor,
                adUnitExtrasDecoder: adUnit.extras
            ) { [weak self] result in
                guard let self = self else { return }
                defer { group.leave() }
                
                switch result {
                case .failure(let error):
                    let event = DirectDemandProividerDidFailToLoadMediationEvent(
                        roundConfiguration: self.roundConfiguration,
                        adapter: adapter,
                        error: error
                    )
                    self.observer.log(event)
                case .success(let ad):
                    #warning("Bid")
//                    let bid = BidType(
//                        id: UUID().uuidString,
//                        adType: self.context.adType,
//                        adUnit: adUnit,
//                        demandType: <#T##DemandType#>, ad: ad, provider: provider, roundConfiguration: self., auctionConfiguration: <#T##AuctionConfiguration#>)
//                    let event = DirectDemandProividerDidLoadMediationEvent(roundConfiguration: self.roundConfiguration, adapter: adapter, bid: <#T##AnyBid#>)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.isExecuting else { return }
            self.finish()
        }
    }
}


extension AuctionOperationRequestDirectDemand: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }

        #warning("Log events")
//        observer.log(
//            DirectDemandProividerDidFailToLoadMediationEvent(
//                roundConfiguration: roundConfiguration,
//                adapter: adapter,
//                error: .fillTimeoutReached
//            )
//        )

        finish()
    }
}
