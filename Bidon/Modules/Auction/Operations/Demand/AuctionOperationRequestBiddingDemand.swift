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
    
    private var bidders: [AdapterType] {
        return encoders
            .keys
            .compactMap { id in
                adapters.first { $0.identifier == id }
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
        
        // Observe bid request start
        observeBidRequests(bidders: bidders)
        
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
            switch result {
            case .success(let response):
                self?.proceedBidResponse(response)
            case .failure(let error):
                guard let self = self else { return }
                Logger.warning("Bid request failed with error \(error)")
                self.observeNoBids(bidders: self.bidders)
                self.finish()
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
            observeNoBids(bidders: bidders)
            finish()
            return
        }
        
        let bidId = UUID().uuidString
        
        observeNoBids(bidders: bidders.filter { $0.identifier != adapter.identifier })
        observeBid(bidId: bidId, bidder: adapter, response: response)
        observeFillRequest(bidId: bidId, bidder: adapter, response: response)
        
        provider.prepareBid(with: response.bid.payload) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            defer { self.finish() }
            
            switch result {
            case .failure(let error):
                Logger.warning("Provider did fail to load with error: \(error)")
                self.observeNoFill(bidder: adapter)
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
                
                self.bid = bid
                
                self.observeFill(bidder: adapter, bid: bid)
            }
        }
    }
    
    // MARK: Observing
    private func observeBidRequests(bidders: [AdapterType]) {
        bidders.forEach { adapter in
            let event = MediationEvent.bidRequest(
                round: round,
                adapter: adapter,
                isBidding: true
            )
            
            observer.log(event)
        }
    }
    
    private func observeNoBids(bidders: [AdapterType]) {
        bidders.forEach { adapter in
            let event = MediationEvent.bidError(
                round: round,
                adapter: adapter,
                error: .noBid,
                isBidding: true
            )
            observer.log(event)
        }
    }
    
    private func observeBid(
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
    
    private func observeFillRequest(
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
    
    private func observeNoFill(bidder: AdapterType) {
        let event = MediationEvent.fillError(
            round: round,
            adapter: bidder,
            error: .noFill,
            isBidding: true
        )
        
        observer.log(event)
    }
    
    private func observeFill(
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
        
        #warning("Handle timeout correctly")
        finish()
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
