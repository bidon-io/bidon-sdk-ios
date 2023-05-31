//
//  RequestDirectDemandOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationRequestDirectDemand<DemandProviderType: DemandProvider>: AsynchronousOperation {
    typealias BidType = BidModel<DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<DemandProviderType>
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let adapter: AnyDemandSourceAdapter<DemandProviderType>
    
    let lineItem: (AdapterType, Price) -> LineItem?
    
    private(set) var bid: BidType?
    
    init(
        round: AuctionRound,
        observer: AnyMediationObserver,
        adapter: AnyDemandSourceAdapter<DemandProviderType>,
        lineItem: @escaping (AdapterType, Price) -> LineItem?
    ) {
        self.round = round
        self.observer = observer
        self.adapter = adapter
        self.lineItem = lineItem
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        guard let provider = adapter.provider as? any DirectDemandProvider else {
            fatalError("Inconsistent provider")
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.load(direct: provider)
        }
    }
    
    private func load(direct provider: any DirectDemandProvider) {
        guard let lineItem = lineItem(adapter, pricefloor) else {
            let event = MediationEvent.lineItemNotFound(
                round: round,
                adapter: adapter
            )
            observer.log(event)
            finish()
            return
        }
        
        let event = MediationEvent.loadRequest(
            round: round,
            adapter: adapter,
            lineItem: lineItem
        )
        
        observer.log(event)
        
        provider.load(lineItem.adUnitId) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                let event = MediationEvent.loadError(
                    round: self.round,
                    adapter: self.adapter,
                    error: error
                )
                self.observer.log(event)
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    lineItem: lineItem,
                    ad: ad,
                    provider: self.adapter.provider
                )
                
                let event = MediationEvent.loadResponse(
                    round: self.round,
                    adapter: self.adapter,
                    bid: bid
                )
                
                self.observer.log(event)
                self.bid = bid
                self.finish()
            }
        }
    }
}


extension AuctionOperationRequestDirectDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        
        let event = MediationEvent.loadError(
            round: round,
            adapter: adapter,
            error: .fillTimeoutReached
        )
        
        observer.log(event)
        finish()
    }
}
