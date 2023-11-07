//
//  AuctionOperationPergformBidRequest.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.11.2023.
//

import Foundation


final class AuctionOperationPerformBidRequest<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperation {
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    
    let observer: AnyAuctionObserver
    let adapters: [AdapterType]
    let demands: [String]
    let adUnitProvider: AdUnitProvider
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private var tokens: [BiddingDemandToken] {
        deps(AuctionOperationCollectBiddingContext<AdTypeContextType>.self)
            .reduce([]) { $0 + $1.tokens }
    }
    
    private var bidfloor: Price {
        deps(AuctionOperationStartRound<AdTypeContextType, BidType>.self)
            .reduce(0.0) { max($0, $1.pricefloor) }
    }
    
    private var bidders: [AdapterType] {
        let demandIds = Set(tokens.map { $0.demandId })
        return adapters.filter { demandIds.contains($0.demandId) }
    }
    
    private(set) var bids: [ServerBidModel] = []

    
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
        
        guard !tokens.isEmpty else {
            finish()
            return
        }
        
        let event = BiddingDemandBidRequestAuctionEvent(
            configuration: roundConfiguration,
            adapters: bidders
        )
        observer.log(event)
        
        // Make bid request
        let request = context.bidRequest { builder in
            builder.withBidfloor(bidfloor)
            builder.withBiddingTokens(tokens)
            builder.withTestMode(sdk.isTestMode)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withAuctionId(auctionConfiguration.auctionId)
            builder.withAuctionConfigurationUid(auctionConfiguration.auctionConfigurationUid)
            builder.withRoundId(roundConfiguration.roundId)
            builder.withAdapters(adapters)
        }
        
        networkManager.perform(request: request) { [weak self] result in
            guard let self = self else { return }
            defer { self.finish() }
            
            switch result {
            case .success(let response):
                let event = BiddingDemandBidResponseAuctionEvent(
                    configuration: self.roundConfiguration,
                    bids: response.bids
                )
                self.observer.log(event)
    
                self.bids = response.bids
            case .failure:
                self.bidders.map { bidder in
                    BiddingDemandErrorAuctionEvent(
                        configuration: self.roundConfiguration,
                        demandId: bidder.demandId,
                        error: .noBid
                    )
                }.forEach(observer.log)
            }
        }
    }
}


extension AuctionOperationPerformBidRequest: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }

        bidders.map { adapter in
            BiddingDemandErrorAuctionEvent(
                configuration: roundConfiguration,
                demandId: adapter.demandId,
                error: .bidTimeoutReached
            )
        }.forEach(observer.log)
                
        finish()
    }
}
