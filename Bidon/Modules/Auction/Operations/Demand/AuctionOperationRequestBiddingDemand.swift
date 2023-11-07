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
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    private var serverBids: [ServerBidModel] {
        deps(AuctionOperationPerformBidRequest<AdTypeContextType>.self)
            .reduce([]) { $0 + $1.bids }
    }
    
    private var activeServerBids = Set<ServerBidModel>()
    
    private(set) var bids: [BidType] = []
    
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        self.roundConfiguration = builder.roundConfiguration
        self.context = builder.context
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
        for serverBid in serverBids {
            guard
                let adapter = adapters.first(where: { $0.demandId == serverBid.adUnit.demandId }),
                let provider = adapter.provider as? any GenericBiddingDemandProvider
            else {
                let event = BiddingDemandLoadingErrorAucitonEvent(
                    configuration: roundConfiguration,
                    bid: serverBid,
                    error: .unknownAdapter
                )
                observer.log(event)
                
                continue
            }
            
            group.enter()
            
            let event = BiddingDemandWillLoadAuctionEvent(
                configuration: roundConfiguration,
                bid: serverBid
            )
            observer.log(event)
            
            provider.load(
                payloadDecoder: serverBid.payload,
                adUnitExtrasDecoder: serverBid.adUnit.extras
            ) { [weak self] result in
                guard let self = self else { return }
                defer { group.leave() }
                
                switch result {
                case .failure(let error):
                    let event = BiddingDemandLoadingErrorAucitonEvent(
                        configuration: self.roundConfiguration,
                        bid: serverBid,
                        error: error
                    )
                    self.observer.log(event)
                case .success(let ad):
                    let bid = BidType(
                        id: serverBid.id,
                        adType: self.context.adType,
                        adUnit: serverBid.adUnit,
                        price: ad.price ?? serverBid.price,
                        ad: ad,
                        provider: adapter.provider,
                        roundConfiguration: self.roundConfiguration,
                        auctionConfiguration: self.auctionConfiguration
                    )
                    
                    let event = BiddingDemandDidLoadAuctionEvent(bid: bid)
                    self.observer.log(event)
                    
                    self.bids.append(bid)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.isExecuting else { return }
            self.finish()
        }
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }

        activeServerBids.map { bid in
            BiddingDemandErrorAuctionEvent(
                configuration: roundConfiguration,
                demandId: bid.adUnit.demandId,
                error: .fillTimeoutReached
            )
        }.forEach(observer.log)
                
        finish()
    }
}
