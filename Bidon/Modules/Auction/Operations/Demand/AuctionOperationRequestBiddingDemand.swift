//
//  AuctionOperationRequestBiddingDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


final class AuctionOperationRequestBiddingDemand<BidRequestBuilderType, DemandProviderType>: AsynchronousOperation
where BidRequestBuilderType: BidRequestBuilder, DemandProviderType: DemandProvider {
    typealias BidType = BidModel<DemandProviderType>
    typealias AdapterType = AnyDemandSourceAdapter<DemandProviderType>
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    let observer: AnyMediationObserver
    let adapters: [AdapterType]
    
    private var encoders: BiddingContextEncoders = [:]
    
    init(
        observer: AnyMediationObserver,
        adapters: [AdapterType]
    ) {
        self.observer = observer
        self.adapters = adapters
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
        
        let request = BidRequest { (builder: BidRequestBuilderType) in
            builder.withBidfloor(pricefloor)
            builder.withBiddingContextEncoders(encoders)
            builder.withTestMode(sdk.isTestMode)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withAuctionId(observer.auctionId)
            builder.withAuctionConfigurationId(observer.auctionConfigurationId)
        }
        
        networkManager.perform(request: request) { result in
            
        }
    }
}


extension AuctionOperationRequestBiddingDemand: AuctionOperationRequestDemand {
    func timeoutReached() {
        guard isExecuting else { return }
        finish()
    }
}
