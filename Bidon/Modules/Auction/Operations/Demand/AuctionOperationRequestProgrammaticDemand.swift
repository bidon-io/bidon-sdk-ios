//
//  ConcurrentAuctionRequestProgrammaticDemandOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 22.04.2023.
//

import Foundation


final class AuctionOperationRequestProgrammaticDemand<AuctionContextType: AuctionContext>: AsynchronousOperation {
    private enum BidState {
        case unknown
        case bidding
        case filling(BidType)
        case ready(BidType)
    }
    
    typealias BidType = BidModel<AuctionContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AuctionContextType.DemandProviderType>
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let adapter: AdapterType
    
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
        adapter: AdapterType
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
        observer.log(
            ProgrammaticDemandProviderRequestBidMediationEvent(
                round: round,
                adapter: adapter
            )
        )
        
        bidState = .bidding
        
        provider.bid(pricefloor) { [weak self, unowned provider] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                self.observer.log(
                    ProgrammaticDemandProviderBidErrorMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        error: error
                    )
                )
                
                self.bidState = .unknown
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    id: UUID().uuidString,
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    ad: ad,
                    provider: self.adapter.provider
                )
                
                self.observer.log(
                    ProgrammaticDemandProviderDidReceiveBidMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        bid: bid
                    )
                )
                self.bidState = .filling(bid)
                
                DispatchQueue.main.async { [unowned self] in
                    self.fill(programmatic: provider, bid: bid)
                }
            }
        }
    }
    
    private func fill(programmatic provider: any ProgrammaticDemandProvider, bid: BidType) {
        observer.log(
            ProgrammaticDemandProviderRequestFillMediationEvent(
                round: round,
                adapter: adapter,
                bid: bid
            )
        )
        
        provider.fill(opaque: bid.ad) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                self.observer.log(
                    ProgrammaticDemandProviderDidFailToFillBidMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        error: error
                    )
                )
                
                self.bidState = .unknown
                self.finish()
            case .success:
                self.observer.log(
                    ProgrammaticDemandProviderDidFillBidMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        bid: bid
                    )
                )
                
                self.bidState = .ready(bid)
                self.finish()
            }
        }
    }
}


extension AuctionOperationRequestProgrammaticDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        defer { finish() }
        
        switch bidState {
        case .bidding:
            observer.log(
                ProgrammaticDemandProviderBidErrorMediationEvent(
                    round: round,
                    adapter: adapter,
                    error: MediationError.bidTimeoutReached
                )
            )
        case .filling:
            observer.log(
                ProgrammaticDemandProviderDidFailToFillBidMediationEvent(
                    round: round,
                    adapter: adapter,
                    error: MediationError.bidTimeoutReached
                )
            )
        default:
            observer.log(
                ProgrammaticDemandProviderBidErrorMediationEvent(
                    round: round,
                    adapter: adapter,
                    error: MediationError.unscpecifiedException
                )
            )
        }
    }
}
