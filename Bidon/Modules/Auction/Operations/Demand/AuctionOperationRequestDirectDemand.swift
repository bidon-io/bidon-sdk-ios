//
//  RequestDirectDemandOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationRequestDirectDemand<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperationRequestDemand {
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    
    let observer: AnyAuctionObserver
    let adapters: [AdapterType]
    let demands: [String]
    let adUnitProvider: AdUnitProvider
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    private(set) var bids: [BidType] = []
    private var activeAdUnits = Set<AdUnitModel>()
   
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.observer = builder.observer
        self.context = builder.context
        self.roundConfiguration = builder.roundConfiguration
        self.auctionConfiguration = builder.auctionConfiguration
        self.adUnitProvider = builder.adUnitProvider
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
        for demandId in demands {
            guard
                let adapter = adapters.first(where: { $0.demandId == demandId }),
                let provider = adapter.provider as? any GenericDirectDemandProvider
            else {
                let event = DirectDemandErrorAuctionEvent(
                    configuration: roundConfiguration,
                    demandId: demandId,
                    error: .unknownAdapter
                )
                observer.log(event)
                
                continue
            }
            
            guard let adUnit = adUnitProvider.directAdUnit(for: demandId, pricefloor: pricefloor) else {
                let event = DirectDemandErrorAuctionEvent(
                    configuration: roundConfiguration,
                    demandId: demandId,
                    error: .noAppropriateAdUnitId
                )
                observer.log(event)
                
                continue
            }
            
            group.enter()
            
            let event = DirectDemandWillLoadAuctionEvent(
                configuration: roundConfiguration,
                adUnit: adUnit
            )
            observer.log(event)
            
            activeAdUnits.insert(adUnit)
            
            provider.load(
                pricefloor: pricefloor,
                adUnitExtrasDecoder: adUnit.extras
            ) { [weak self] result in
                guard let self = self else { return }
                defer { group.leave() }
                defer { self.activeAdUnits.remove(adUnit) }
                
                switch result {
                case .failure(let error):
                    let event = DirectDemandLoadingErrorAucitonEvent(
                        configuration: self.roundConfiguration,
                        adUnit: adUnit,
                        error: error
                    )
                    self.observer.log(event)
                case .success(let ad):
                    let bid = BidType(
                        id: UUID().uuidString,
                        impressionId: UUID().uuidString,
                        adType: self.context.adType,
                        adUnit: adUnit,
                        price: ad.price ?? adUnit.pricefloor,
                        ad: ad,
                        provider: adapter.provider,
                        roundConfiguration: self.roundConfiguration,
                        auctionConfiguration: self.auctionConfiguration
                    )
                    
                    let event = DirectDemandDidLoadAuctionEvent(bid: bid)
                    self.observer.log(event)
                    
                    self.bids.append(bid)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.isExecuting else { return }
            self.finish()
        }
    }
}


extension AuctionOperationRequestDirectDemand: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        guard isExecuting else { return }

        activeAdUnits.map { adUnit in
            DirectDemandLoadingErrorAucitonEvent(
                configuration: roundConfiguration,
                adUnit: adUnit,
                error: .fillTimeoutReached
            )
        }.forEach(observer.log)
        
        activeAdUnits.removeAll()

        finish()
    }
}
