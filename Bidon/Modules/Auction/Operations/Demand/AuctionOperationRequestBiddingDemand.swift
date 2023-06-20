//
//  AuctionOperationRequestBiddingDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


final class AuctionOperationRequestBiddingDemand<AuctionContextType: AuctionContext>: AsynchronousOperation {
    private enum BidState {
        case unknown
        case prepare([AdapterType])
        case bidding([AdapterType])
        case filling(AdapterType)
        case ready(BidType)
    }
    
    typealias BidType = BidModel<AuctionContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AuctionContextType.DemandProviderType>
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    @Atomic private var bidState: BidState = .unknown
    
    let context: AuctionContextType
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    let round: AuctionRound
    
    private var encoders: BiddingContextEncoders = [:]
    
    var bid: BidType? {
        switch bidState {
        case .ready(let bid): return bid
        default: return nil
        }
    }
    
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
        
        let bidders: [AdapterType] = adapters.compactMap { adapter in
            guard let provider = adapter.provider as? any BiddingDemandProvider else { return nil }
            
            group.enter()
            provider.fetchBiddingContext { [weak self] result in
                defer { group.leave() }
                guard let self = self else { return }
                
                switch result {
                case .success(let encoder):
                    self.encoders[adapter.identifier] = encoder
                default:
                    break
                }
            }
            
            return adapter
        }
        
        $bidState.mutate { $0 = .prepare(bidders) }
        
        group.notify(queue: .main) { [weak self] in
            self?.performBidRequest()
        }
    }
    
    func performBidRequest() {
        guard isExecuting else { return }
        
        guard !encoders.isEmpty else {
            $bidState.mutate { $0 = .unknown }
            finish()
            return
        }
        
        let bidders: [AdapterType] = encoders.keys.compactMap { key in
            adapters.first { $0.identifier == key }
        }
        
        $bidState.mutate { $0 = .bidding(bidders) }
        
        // Observe bid request start
        observer.log(
            BiddingDemandProviderRequestBidMediationEvent(
                round: round,
                adapters: bidders
            )
        )
        
        // Make bid request
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
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.proceedBidResponse(response, bidders: bidders)
            case .failure:
                self.$bidState.mutate { $0 = .unknown }
                self.observer.log(
                    BiddingDemandProviderBidErrorMediationEvent(
                        round: self.round,
                        adapters: bidders,
                        error: .noBid
                    )
                )
                self.finish()
            }
        }
    }
    
    func proceedBidResponse(_ response: BidRequest.ResponseBody, bidders: [AdapterType]) {
        guard isExecuting else { return }
        
        guard
            let adapter = bidders.first(where: { $0.identifier == response.bid.demandId }),
            let provider = adapter.provider as? any BiddingDemandProvider
        else {
            $bidState.mutate { $0 = .unknown }
            observer.log(
                BiddingDemandProviderBidErrorMediationEvent(
                    round: self.round,
                    adapters: bidders,
                    error: .unknownAdapter
                )
            )
            finish()
            return
        }
        
        $bidState.mutate { $0 = .filling(adapter) }
        
        observer.log(
            BiddingDemandProviderFillRequestMediationEvent(
                round: self.round,
                adapter: adapter,
                bid: response.bid
            )
        )
        
        provider.prepareBid(with: response.bid.payload) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            defer { self.finish() }
            
            switch result {
            case .failure(let error):
                self.$bidState.mutate { $0 = .unknown }
                self.observer.log(
                    BiddingDemandProviderFillErrorMediationEvent(
                        round: self.round,
                        adapter: adapter,
                        error:error
                    )
                )
            case .success(let ad):
                let bid = BidType(
                    id: UUID().uuidString,
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: adapter.provider
                )
                
                self.$bidState.mutate { $0 = .ready(bid) }
                self.observer.log(
                    BiddingDemandProviderDidFillMediationEvent(
                        round: self.round,
                        adapter: adapter,
                        bid: bid
                    )
                )
            }
        }
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        defer { finish() }
        
        switch bidState {
        case .prepare(let bidders), .bidding(let bidders):
            observer.log(
                BiddingDemandProviderBidErrorMediationEvent(
                    round: round,
                    adapters: bidders,
                    error: .bidTimeoutReached
                )
            )
        case .filling(let bidder):
            observer.log(
                BiddingDemandProviderFillErrorMediationEvent(
                    round: round,
                    adapter: bidder,
                    error: .fillTimeoutReached
                )
            )
        default:
            break
        }
    }
}
