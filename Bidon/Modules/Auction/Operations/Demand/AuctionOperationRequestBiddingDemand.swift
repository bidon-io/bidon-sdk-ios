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
        
        guard isExecuting else { return }
                
        guard
            let adapter = adapters.first(where: { $0.demandId == demand && $0.provider is any GenericBiddingDemandProvider }),
            let provider = adapter.provider as? any GenericBiddingDemandProvider
        else {
            let event = BiddingDemandLoadingErrorAucitonEvent(
                adUnit: adUnit,
                error: .unknownAdapter
            )
            observer.log(event)
            
            finish()
            return
        }

        
        let event = BiddingDemandWillLoadAuctionEvent(
            adUnit: adUnit
        )
        observer.log(event)
        
        provider.load(
            payloadDecoder: adUnit.extras,
            adUnitExtrasDecoder: adUnit.extras
        ) { [weak self] result in
            guard let self = self else { return }
            defer {
                self.finish()
            }
            
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
                let event = BiddingDemandLoadingErrorAucitonEvent(
                    adUnit: adUnit,
                    error: error
                )
                self.observer.log(event)
            }
        }
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }
                
        finish()
        
        observer.log(
            BiddingDemandErrorAuctionEvent(
                demandId: adUnit.demandId,
                error: .fillTimeoutReached
            )
        )
    }
}
