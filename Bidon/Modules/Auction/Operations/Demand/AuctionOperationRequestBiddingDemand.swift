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
                case .failure:
                    self.logNoBidEvent(bidders: [adapter], reason: .unscpecifiedException)
                }
            }
            
            return adapter
        }
        
        bidState = .prepare(bidders)
        
        group.notify(queue: .main) { [weak self] in
            self?.performBidRequest()
        }
    }
    
    func performBidRequest() {
        guard isExecuting else { return }
        
        guard !encoders.isEmpty else {
            bidState = .unknown
            finish()
            return
        }
        
        let bidders: [AdapterType] = encoders.keys.compactMap { key in
            adapters.first { $0.identifier == key }
        }
        
        bidState = .bidding(bidders)
        
        // Observe bid request start
        logBidRequestSentEvent(bidders: bidders)
        
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
                self.bidState = .unknown
                self.logNoBidEvent(bidders: bidders)
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
            bidState = .unknown
            logNoBidEvent(bidders: bidders)
            finish()
            return
        }
        
        bidState = .filling(adapter)
        let bidId = UUID().uuidString
        
        logNoBidEvent(bidders: bidders.filter { $0.identifier != adapter.identifier })
        logBidEvent(bidId: bidId, bidder: adapter, response: response)
        logFillEvent(bidId: bidId, bidder: adapter, response: response)
        
        provider.prepareBid(with: response.bid.payload) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            defer { self.finish() }
            
            switch result {
            case .failure:
                self.bidState = .unknown
                self.logNoFillEvent(bidder: adapter)
            case .success(let ad):
                let bid = BidType(
                    id: bidId,
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: adapter.provider
                )
                
                self.bidState = .ready(bid)
                self.logFillEvent(bidder: adapter, bid: bid)
            }
        }
    }
    
    // MARK: Logging
    private func logBidRequestSentEvent(bidders: [AdapterType]) {
        bidders.forEach { adapter in
            let event = MediationEvent.bidRequest(
                round: round,
                adapter: adapter,
                isBidding: true
            )
            
            observer.log(event)
        }
    }
    
    private func logNoBidEvent(
        bidders: [AdapterType],
        reason: MediationError = .noBid
    ) {
        bidders.forEach { adapter in
            let event = MediationEvent.bidError(
                round: round,
                adapter: adapter,
                error: reason,
                isBidding: true
            )
            observer.log(event)
        }
    }
    
    private func logBidEvent(
        bidId: String,
        bidder: AdapterType,
        response: BidRequest.ResponseBody
    ) {
        let bid = BidType(
            id: bidId,
            auctionId: observer.auctionId,
            auctionConfigurationId: observer.auctionConfigurationId,
            roundId: round.id,
            adType: observer.adType,
            ad: BidResponseAd(bid: response.bid),
            provider: bidder.provider
        )
        
        let event = MediationEvent.bidResponse(
            round: round,
            adapter: bidder,
            bid: bid,
            isBidding: true
        )
        observer.log(event)
    }
    
    private func logFillEvent(
        bidId: String,
        bidder: AdapterType,
        response: BidRequest.ResponseBody
    ) {
        let bid = BidType(
            id: bidId,
            auctionId: observer.auctionId,
            auctionConfigurationId: observer.auctionConfigurationId,
            roundId: round.id,
            adType: observer.adType,
            ad: BidResponseAd(bid: response.bid),
            provider: bidder.provider
        )
        
        let event = MediationEvent.fillRequest(
            round: round,
            adapter: bidder,
            bid: bid,
            isBidding: true
        )
        
        observer.log(event)
    }
    
    private func logNoFillEvent(
        bidder: AdapterType,
        reason: MediationError = .noFill
    ) {
        let event = MediationEvent.fillError(
            round: round,
            adapter: bidder,
            error: reason,
            isBidding: true
        )
        
        observer.log(event)
    }
    
    private func logFillEvent(
        bidder: AdapterType,
        bid: any Bid
    ) {
        let event = MediationEvent.fillResponse(
            round: round,
            adapter: bidder,
            bid: bid,
            isBidding: true
        )
        observer.log(event)
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        defer { finish() }

        switch bidState {
        case .prepare(let bidders), .bidding(let bidders):
            logNoBidEvent(
                bidders: bidders,
                reason: .bidTimeoutReached
            )
        case .filling(let bidder):
            logNoFillEvent(
                bidder: bidder,
                reason: .fillTimeoutReached
            )
        default:
            break
        }
    }
}


fileprivate class BidResponseAd: DemandAd {
    let dsp: String?
    let id: String
    let networkName: String
    var eCPM: Price
    
    init(bid: BidRequest.ResponseBody.BidModel) {
        self.id = bid.id
        self.networkName = bid.demandId
        self.eCPM = bid.price
        self.dsp = nil
    }
}
