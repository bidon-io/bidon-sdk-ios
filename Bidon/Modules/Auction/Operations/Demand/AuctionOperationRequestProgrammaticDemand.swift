//
//  ConcurrentAuctionRequestProgrammaticDemandOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 22.04.2023.
//

import Foundation


final class AuctionOperationRequestProgrammaticDemand<DemandProviderType: DemandProvider>: AsynchronousOperation {
    private enum BidState {
        case unknown
        case bidding
        case filling(BidType)
        case ready(BidType)
    }
    
    typealias BidType = BidModel<DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<DemandProviderType>
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let adapter: AnyDemandSourceAdapter<DemandProviderType>
    
    @Atomic private var bidState: BidState = .unknown
    
    var bid: BidType? {
        switch bidState {
        case .ready(let bid):
            return bid
        default:
            return nil
        }
    }

    init(
        round: AuctionRound,
        observer: AnyMediationObserver,
        adapter: AnyDemandSourceAdapter<DemandProviderType>
    ) {
        self.round = round
        self.observer = observer
        self.adapter = adapter
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        guard let provider = adapter.provider as? any ProgrammaticDemandProvider else {
            fatalError("Inconsistent provider")
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.bid(programmatic: provider)
        }
    }
    
    private func bid(programmatic provider: any ProgrammaticDemandProvider) {
        let event = MediationEvent.bidRequest(
            round: round,
            adapter: adapter
        )
        
        observer.log(event)
        bidState = .bidding
        
        provider.bid(pricefloor) { [weak self, unowned provider] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                let event = MediationEvent.bidError(
                    round: self.round,
                    adapter: self.adapter,
                    error: error
                )
                
                self.observer.log(event)
                self.bidState = .unknown
                
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: self.adapter.provider
                )
                
                let event = MediationEvent.bidResponse(
                    round: self.round,
                    adapter: self.adapter,
                    bid: bid
                )
                
                self.observer.log(event)
                self.bidState = .filling(bid)
                
                DispatchQueue.main.async { [unowned self] in
                    self.fill(programmatic: provider, bid: bid)
                }
            }
        }
    }
    
    private func fill(programmatic provider: any ProgrammaticDemandProvider, bid: BidType) {
        let event = MediationEvent.fillRequest(
            round: round,
            adapter: adapter,
            bid: bid
        )
        observer.log(event)
        
        provider.fill(opaque: bid.ad) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                let event = MediationEvent.fillError(
                    round: self.round,
                    adapter: self.adapter,
                    error: error
                )
                
                self.observer.log(event)
                self.bidState = .unknown
                
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: self.adapter.provider
                )
                
                let event = MediationEvent.fillResponse(
                    round: self.round,
                    adapter: self.adapter,
                    bid: bid
                )
                
                self.observer.log(event)
                self.bidState = .ready(bid)
                
                self.finish()
            }
        }
    }
}


extension AuctionOperationRequestProgrammaticDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }

        let event: MediationEvent
        
        switch bidState {
        case .bidding:
            event = .bidError(
                round: round,
                adapter: adapter,
                error: .bidTimeoutReached
            )
        case .filling:
            event = .fillError(
                round: round,
                adapter: adapter,
                error: .fillTimeoutReached
            )
        default:
            event = .bidError(
                round: round,
                adapter: adapter,
                error: .unscpecifiedException
            )
        }
        
        observer.log(event)
        finish()
    }
}
