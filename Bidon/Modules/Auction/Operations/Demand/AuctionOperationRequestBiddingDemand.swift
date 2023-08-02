//
//  AuctionOperationRequestBiddingDemand.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


final class AuctionOperationRequestBiddingDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation {
    private enum BidState {
        case unknown
        case prepare([AdapterType])
        case bidding([AdapterType])
        case filling(AdapterType)
        case ready(BidType)
    }
    
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    @Atomic private var bidState: BidState = .unknown
    
    let context: AdTypeContextType
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    let round: AuctionRound
    let metadata: AuctionMetadata
    
    private var encoders: BiddingContextEncoders = [:]
    
    var bid: BidType? {
        switch bidState {
        case .ready(let bid): return bid
        default: return nil
        }
    }
    
    init(
        round: AuctionRound,
        adapters: [AdapterType],
        observer: AnyMediationObserver,
        context: AdTypeContextType,
        metadata: AuctionMetadata
    ) {
        self.metadata = metadata
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
            provider.fetchBiddingContextEncoder { [weak self] result in
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
        
        $bidState.wrappedValue = .prepare(bidders)
        
        group.notify(queue: .main) { [weak self] in
            self?.performBidRequest()
        }
    }
    
    func performBidRequest() {
        guard isExecuting else { return }
        
        guard !encoders.isEmpty else {
            $bidState.wrappedValue = .unknown
            finish()
            return
        }
        
        let bidders: [AdapterType] = encoders.keys.compactMap { key in
            adapters.first { $0.identifier == key }
        }
        
        $bidState.wrappedValue = .bidding(bidders)
        
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
            builder.withAuctionId(metadata.id)
            builder.withAuctionConfigurationId(metadata.configuration)
            builder.withRoundId(round.id)
            builder.withAdapters(adapters)
        }
        
        networkManager.perform(request: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.observer.log(
                    BiddingDemandProviderBidResponseMediationEvent(
                        round: self.round,
                        adapters: bidders,
                        bids: response.bids
                    )
                )
                self.proceedBidResponse(response, bidders: bidders)
            case .failure:
                self.$bidState.wrappedValue = .unknown
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
    
    func proceedBidResponse(
        _ response: BidRequest.ResponseBody,
        bidders: [AdapterType],
        previousBid: BidRequest.ResponseBody.BidModel? = nil
    ) {
        guard isExecuting else { return }
        
        guard let pendingServerBid = response.bids.next(previous: previousBid) else {
            $bidState.wrappedValue = .unknown
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
        
        guard
            let demand = pendingServerBid.demands.decoders.first,
            let adapter = bidders.first(where: { $0.identifier == demand.key }),
            let provider = adapter.provider as? any BiddingDemandProvider
        else {
            proceedBidResponse(
                response,
                bidders: bidders,
                previousBid: pendingServerBid
            )
            return
        }
        
        $bidState.wrappedValue = .filling(adapter)
        
        observer.log(
            BiddingDemandProviderFillRequestMediationEvent(
                round: self.round,
                adapter: adapter,
                bid: pendingServerBid
            )
        )
        
        provider.prepareBid(from: demand.value) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                self.$bidState.wrappedValue = .unknown
                self.observer.log(
                    BiddingDemandProviderFillErrorMediationEvent(
                        round: self.round,
                        adapter: adapter,
                        error:error
                    )
                )
                self.proceedBidResponse(
                    response,
                    bidders: bidders,
                    previousBid: pendingServerBid
                )
            case .success(let ad):
                let bid = BidType(
                    id: pendingServerBid.id,
                    roundId: self.round.id,
                    adType: self.context.adType,
                    eCPM: (ad.eCPM != nil && ad.eCPM != .unknown) ? ad.eCPM! : pendingServerBid.price,
                    ad: ad,
                    provider: adapter.provider,
                    metadata: self.metadata
                )
                
                self.$bidState.wrappedValue = .ready(bid)
                self.observer.log(
                    BiddingDemandProviderDidFillMediationEvent(
                        round: self.round,
                        adapter: adapter,
                        bid: bid
                    )
                )
                self.finish()
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


extension Array where Element == BidRequest.ResponseBody.BidModel {
    func next(previous: Element?) -> Element? {
        guard let previous = previous else { return first }
        guard
            let index = firstIndex(of: previous),
            index < (count - 1)
        else { return nil }
        
        return self[index + 1]
    }
}
