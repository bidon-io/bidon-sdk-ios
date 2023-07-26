//
//  ConcurrentAuctionRequestProgrammaticDemandOperation.swift
//  Bidon
//
//  Created by Bidon Team on 22.04.2023.
//

import Foundation


final class AuctionOperationRequestProgrammaticDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation {
    private enum BidState {
        case unknown
        case bidding
        case filling(BidType)
        case ready(BidType)
    }
    
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let adapter: AdapterType
    let metadata: AuctionMetadata
    let context: AdTypeContextType
    
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
        adapter: AdapterType,
        observer: AnyMediationObserver,
        context: AdTypeContextType,
        metadata: AuctionMetadata
    ) {
        self.round = round
        self.observer = observer
        self.adapter = adapter
        self.metadata = metadata
        self.context = context
        
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
        
        $bidState.wrappedValue = .bidding
        
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
                
                self.$bidState.wrappedValue = .unknown
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    id: UUID().uuidString,
                    roundId: self.round.id,
                    adType: self.context.adType,
                    ad: ad,
                    provider: self.adapter.provider,
                    metadata: self.metadata
                )
                
                self.observer.log(
                    ProgrammaticDemandProviderDidReceiveBidMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        bid: bid
                    )
                )
                self.$bidState.wrappedValue = .filling(bid)
                
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
                
                self.$bidState.wrappedValue = .unknown
                self.finish()
            case .success:
                self.observer.log(
                    ProgrammaticDemandProviderDidFillBidMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        bid: bid
                    )
                )
                
                self.$bidState.wrappedValue = .ready(bid)
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
