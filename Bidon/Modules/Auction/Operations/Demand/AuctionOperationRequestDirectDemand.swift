//
//  RequestDirectDemandOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationRequestDirectDemand<AuctionContextType: AuctionContext>: AsynchronousOperation {
    typealias BidType = BidModel<AuctionContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AuctionContextType.DemandProviderType>
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let adapter: AdapterType
    
    let lineItem: (AdapterType, Price) -> LineItem?
    
    private(set) var bid: BidType?
    
    init(
        round: AuctionRound,
        observer: AnyMediationObserver,
        adapter: AdapterType,
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
            observer.log(
                DirectDemandProviderLineItemNotFoundMediationEvent(
                    round: round,
                    adapter: adapter
                )
            )
            finish()
            return
        }
        
        observer.log(
            DirectDemandProividerLoadRequestMediationEvent(
                round: round,
                adapter: adapter,
                lineItem: lineItem
            )
        )
        
        provider.load(lineItem.adUnitId) { [weak self] result in
            guard let self = self, self.isExecuting else { return }
            
            switch result {
            case .failure(let error):
                self.observer.log(
                    DirectDemandProividerDidFailToLoadMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        error: error
                    )
                )
                self.finish()
            case .success(let ad):
                let bid = BidType(
                    id: UUID().uuidString,
                    auctionId: self.observer.auctionId,
                    auctionConfigurationId: self.observer.auctionConfigurationId,
                    roundId: self.round.id,
                    adType: self.observer.adType,
                    lineItem: lineItem,
                    ad: ad,
                    provider: self.adapter.provider
                )
              
                self.observer.log(
                    DirectDemandProividerDidLoadMediationEvent(
                        round: self.round,
                        adapter: self.adapter,
                        bid: bid
                    )
                )
                
                self.bid = bid
                self.finish()
            }
        }
    }
}


extension AuctionOperationRequestDirectDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        
        observer.log(
            DirectDemandProividerDidFailToLoadMediationEvent(
                round: round,
                adapter: adapter,
                error: .fillTimeoutReached
            )
        )
        
        finish()
    }
}
