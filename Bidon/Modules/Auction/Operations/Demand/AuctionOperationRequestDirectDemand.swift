//
//  RequestDirectDemandOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationRequestDirectDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation {
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    
    let observer: AnyMediationObserver
    let adapter: AdapterType
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let lineItem: (AdapterType, Price) -> LineItem?
    let context: AdTypeContextType
    
    private(set) var bid: BidType?
    
    init(
        adapter: AdapterType,
        observer: AnyMediationObserver,
        context: AdTypeContextType,
        roundConfiguration: AuctionRoundConfiguration,
        auctionConfiguration: AuctionConfiguration,
        lineItem: @escaping (AdapterType, Price) -> LineItem?
    ) {
        self.context = context
        self.observer = observer
        self.adapter = adapter
        self.lineItem = lineItem
        self.roundConfiguration = roundConfiguration
        self.auctionConfiguration = auctionConfiguration
        
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
                    roundConfiguration: roundConfiguration,
                    adapter: adapter
                )
            )
            finish()
            return
        }
        
        observer.log(
            DirectDemandProividerLoadRequestMediationEvent(
                roundConfiguration: roundConfiguration,
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
                        roundConfiguration: self.roundConfiguration,
                        adapter: self.adapter,
                        error: error
                    )
                )
                self.finish()
            case .success(let ad):
                let eCPM = ad.eCPM ?? lineItem.pricefloor
                
                let bid = BidType(
                    id: UUID().uuidString,
                    adType: self.context.adType,
                    eCPM: eCPM,
                    demandType: .direct(lineItem),
                    ad: ad,
                    provider: self.adapter.provider,
                    roundConfiguration: self.roundConfiguration,
                    auctionConfiguration: self.auctionConfiguration
                )
              
                self.observer.log(
                    DirectDemandProividerDidLoadMediationEvent(
                        roundConfiguration: self.roundConfiguration,
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
                roundConfiguration: roundConfiguration,
                adapter: adapter,
                error: .fillTimeoutReached
            )
        )
        
        finish()
    }
}
