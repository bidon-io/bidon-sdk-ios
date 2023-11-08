//
//  AuctionOperationCollectBiddingContextOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.11.2023.
//

import Foundation


final class AuctionOperationCollectBiddingContext<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperation {
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    
    let observer: AnyAuctionObserver
    let adapters: [AdapterType]
    let demands: [String]
    let adUnitProvider: AdUnitProvider
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    private(set) var tokens: [BiddingDemandToken] = []
    private var bidders = Set<AdapterType>()
    
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.observer = builder.observer
        self.adUnitProvider = builder.adUnitProvider
        self.auctionConfiguration = builder.auctionConfiguration
        self.roundConfiguration = builder.roundConfiguration
        self.context = builder.context
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
        
        for demandId in demands {
            guard
                let adapter = adapters.first(where: { $0.demandId == demandId }),
                let provider = adapter.provider as? any GenericBiddingDemandProvider
            else {
                let event = BiddingDemandErrorAuctionEvent(
                    configuration: roundConfiguration,
                    demandId: demandId,
                    error: .unknownAdapter
                )
                observer.log(event)
                
                continue
            }
            
            let adUnitExtras = adUnitProvider.biddingAdUnits(for: demandId).map { $0.extras }
            guard !adUnitExtras.isEmpty else {
                let event = BiddingDemandErrorAuctionEvent(
                    configuration: roundConfiguration,
                    demandId: demandId,
                    error: .noAppropriateAdUnitId
                )
                observer.log(event)
                continue
            }
            
            bidders.insert(adapter)
            
            let event = BiddingDemandWillCollectTokenAuctionEvent(
                configuration: roundConfiguration,
                adapter: adapter
            )
            observer.log(event)
            
            group.enter()
            provider.collectBiddingTokenEncoder(adUnitExtrasDecoder: adUnitExtras) { [weak self] result in
                guard let self = self else { return }
                defer { group.leave() }
                defer { self.bidders.remove(adapter) }
                
                switch result {
                case .failure(let error):
                    let event = BiddingDemandTokenErrorAuctionEvent(
                        configuration: self.roundConfiguration,
                        adapter: adapter,
                        error: error
                    )
                    self.observer.log(event)
                case .success(let token):
                    let demandToken = BiddingDemandToken(
                        demandId: adapter.demandId,
                        token: token
                    )
                    
                    self.tokens.append(demandToken)
                    
                    let event = BiddingDemandDidCollectTokenAuctionEvent(
                        configuration: self.roundConfiguration,
                        token: demandToken
                    )
                    self.observer.log(event)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.isExecuting else { return }
            self.finish()
        }
    }
}


extension AuctionOperationCollectBiddingContext: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }
        
        bidders.map { adapter in
            BiddingDemandTokenErrorAuctionEvent(
                configuration: roundConfiguration,
                adapter: adapter,
                error: .bidTimeoutReached
            )
        }.forEach(observer.log)
        
        bidders.removeAll()
        
        finish()
    }
}
