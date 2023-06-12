//
//  AuctionOperationRequestBiddingDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


final class AuctionOperationRequestBiddingDemand<AuctionContextType: AuctionContext>: AsynchronousOperation {
    typealias BidType = BidModel<AuctionContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AuctionContextType.DemandProviderType>
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    let context: AuctionContextType
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    let round: AuctionRound
    
    private var encoders: BiddingContextEncoders = [:]
    
    private(set) var bid: BidType?
    
    init(
        context: AuctionContextType,
        observer: AnyMediationObserver,
        adapters: [AdapterType],
        round: AuctionRound
    ) {
        self.context = context
        self.observer = observer
        self.adapters = adapters
        self.round = round
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
        
        adapters.forEach { adapter in
            if let provider = adapter.provider as? any BiddingDemandProvider {
                group.enter()
                provider.fetchBiddingContext { [weak self] result in
                    defer { group.leave() }
                    
                    switch result {
                    case .success(let encoder):
                        self?.encoders[adapter.identifier] = encoder
                    case .failure(let error):
                        Logger.warning("\(adapter) failed to fetch bidding context with error \(error)")
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.performBidRequest()
        }
    }
    
    func performBidRequest() {
        guard isExecuting else { return }
        guard !encoders.isEmpty else {
            finish()
            return
        }
        
        let request = context.bidRequest { builder in
            builder.withBidfloor(pricefloor)
            builder.withBiddingContextEncoders(encoders)
            builder.withTestMode(sdk.isTestMode)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withAuctionId(observer.auctionId)
            builder.withAuctionConfigurationId(observer.auctionConfigurationId)
            builder.withRoundId(round.id)
            builder.withAdapters(adapters)
        }
        
        networkManager.perform(request: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.proceedBidResponse(response)
            case .failure(let error):
                Logger.warning("Bid request failed with error \(error)")
                self?.finish()
            }
        }
    }
    
    func proceedBidResponse(_ response: BidRequest.ResponseBody) {
        guard isExecuting else { return }
        
        guard
            let adapter = adapters.first(where: { $0.identifier == response.bid.demandId }),
            let provider = adapter.provider as? any BiddingDemandProvider
        else {
            Logger.warning("No adapter for seat bid demand id \(response.bid.demandId) found")
            finish()
            return
        }
        
        provider.prepareBid(with: response.bid.payload) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            defer { self.finish() }
            
            switch result {
            case .failure(let error):
                Logger.warning("Provider did fail to load with error: \(error)")
            case .success(let ad):
                self.bid = BidType(
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: adapter.provider
                )
            }
        }
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        finish()
    }
}
