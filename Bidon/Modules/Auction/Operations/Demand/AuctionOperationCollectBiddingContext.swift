//
//  AuctionOperationCollectBiddingContextOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.11.2023.
//

import Foundation


final class AuctionOperationCollectBiddingContext<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperation {
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = AuctionOperationRequestDemandBuilder<AdTypeContextType>
    
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    let demands: [String]
    let adUnitProvider: AdUnitProvider
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    let context: AdTypeContextType
    
    private(set) var tokens: [BiddingDemandToken] = []
    
    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.observer = builder.observer
        self.adUnitProvider = builder.adUnitProvider
        self.auctionConfiguration = builder.auctionConfiguration
        self.roundConfiguration = builder.roundConfiguration
        self.context = builder.context
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let group = DispatchGroup()
    
        for demandId in demands {
            guard
                let adapter = adapters.first(where: { $0.demandId == demandId }),
                let provider = adapter.provider as? any GenericBiddingDemandProvider
            else {
                let event = DemandProviderNotFoundMediationEvent(
                    roundConfiguration: roundConfiguration,
                    demandId: demandId
                )
                
                observer.log(event)
                
                continue
            }
            
            let adUnits = adUnitProvider.biddingAdUnits(for: demandId)
            
            for adUnit in adUnits {
                group.enter()
                
                provider.collectBiddingTokenEncoder(adUnitExtrasDecoder: adUnit.extras) { [weak self] result in
                    guard let self = self else { return }
                    defer { group.leave() }
                    
                    switch result {
                    case .failure(let error):
                        #warning("Error")
//                        let event = DemandProviderCollectBiddingTokenEncoderFailedMediationEvent(
//                            roundConfiguration: self.roundConfiguration,
//                            demandId: demandId,
//                            adUnit: adUnit,
//                            error: error
//                        )
//
//                        self.observer.log(event)
                    case .success(let token):
                        let demandToken = BiddingDemandToken(
                            demandId: adapter.demandId,
                            token: token
                        )
                        
                        self.tokens.append(demandToken)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.isExecuting else { return }
            self.finish()
        }
    }
}


extension AuctionOperationCollectBiddingContext: AuctionOperationRoundTimeoutHandler {
    func timeoutReached() {
        #warning("Timeout")
    }
}
