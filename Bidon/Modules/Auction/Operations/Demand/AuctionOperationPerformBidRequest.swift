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
    
    let observer: AnyMediationObserver
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
    
    private(set) var bids: [any PendingBid] = []

    
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
        
        let event = BiddingDemandProviderRequestBidMediationEvent(
            roundConfiguration: roundConfiguration,
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
                self.observer.log(
                    BiddingDemandProviderBidResponseMediationEvent(
                        roundConfiguration: self.roundConfiguration,
                        adapters: self.bidders,
                        bids: response.bids
                    )
                )
                
                self.bids = response.bids
            case .failure:
                self.observer.log(
                    BiddingDemandProviderBidErrorMediationEvent(
                        roundConfiguration: self.roundConfiguration,
                        adapters: self.bidders,
                        error: .noBid
                    )
                )
            }
        }
    }
}


extension AuctionOperationPerformBidRequest: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        finish()
    }
}
