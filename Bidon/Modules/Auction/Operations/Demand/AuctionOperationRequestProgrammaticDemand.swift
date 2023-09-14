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
    
    let observer: AnyMediationObserver
    let adapter: AdapterType
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
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
        adapter: AdapterType,
        observer: AnyMediationObserver,
        context: AdTypeContextType,
        roundConfiguration: AuctionRoundConfiguration,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.observer = observer
        self.adapter = adapter
        self.context = context
        self.roundConfiguration = roundConfiguration
        self.auctionConfiguration = auctionConfiguration
        
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
                roundConfiguration: roundConfiguration,
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
                        roundConfiguration: self.roundConfiguration,
                        adapter: self.adapter,
                        error: error
                    )
                )
                
                self.$bidState.wrappedValue = .unknown
                self.finish()
            case .success(let ad):
                let eCPM = ad.eCPM ?? .unknown
                
                let bid = BidType(
                    id: UUID().uuidString,
                    adType: self.context.adType,
                    eCPM: eCPM,
                    demandType: .programmatic,
                    ad: ad,
                    provider: self.adapter.provider,
                    roundConfiguration: self.roundConfiguration,
                    auctionConfiguration: self.auctionConfiguration
                )
                
                self.observer.log(
                    ProgrammaticDemandProviderDidReceiveBidMediationEvent(
                        roundConfiguration: self.roundConfiguration,
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
                roundConfiguration: roundConfiguration,
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
                        roundConfiguration: self.roundConfiguration,
                        adapter: self.adapter,
                        error: error
                    )
                )
                
                self.$bidState.wrappedValue = .unknown
                self.finish()
            case .success:
                self.observer.log(
                    ProgrammaticDemandProviderDidFillBidMediationEvent(
                        roundConfiguration: self.roundConfiguration,
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
                    roundConfiguration: roundConfiguration,
                    adapter: adapter,
                    error: MediationError.bidTimeoutReached
                )
            )
        case .filling:
            observer.log(
                ProgrammaticDemandProviderDidFailToFillBidMediationEvent(
                    roundConfiguration: roundConfiguration,
                    adapter: adapter,
                    error: MediationError.bidTimeoutReached
                )
            )
        default:
            observer.log(
                ProgrammaticDemandProviderBidErrorMediationEvent(
                    roundConfiguration: roundConfiguration,
                    adapter: adapter,
                    error: MediationError.unscpecifiedException
                )
            )
        }
    }
}
