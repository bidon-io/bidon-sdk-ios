//
//  FinishAuctionOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationFinish<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation, AuctionOperation
where BidType.ProviderType == AdTypeContextType.DemandProviderType, BidType.DemandAdType: DemandAd {
    
    typealias BuilderType = Builder
    
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var completion: ((Result<BidType, SdkError>) -> ())!
        
        @discardableResult
        func withCompletion(_ completion:  @escaping (Result<BidType, SdkError>) -> ()) -> Self {
            self.completion = completion
            return self
        }
    }
    
    let observer: AnyAuctionObserver
    let completion: (Result<BidType, SdkError>) -> ()
    let comparator: AuctionBidComparator
    let auctionConfiguration: AuctionConfiguration
    
    init(builder: Builder) {
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        self.comparator = builder.comparator
        self.completion = builder.completion
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let bids = deps(AuctionOperationFinishRound<AdTypeContextType, BidType>.self)
            .reduce([]) { $0 + $1.bids }
            .sorted { comparator.compare($0, $1) }
        
        let winner = bids.first
        
        observer.log(FinishAuctionEvent(winner: winner))
        
        let result = result(for: bids, winner: winner)
        let completion = self.completion
        
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    override func cancel() {
        super.cancel()
        
        observer.log(CancelAuctionEvent())
        
        let result = Result<BidType, SdkError>.failure(.cancelled)
        let completion = self.completion
        
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    private func result(
        for bids: [BidType],
        winner: BidType?
    ) -> Result<BidType, SdkError> {
        guard let winner = winner else {
            // TODO: Better error handling
            return .failure(.noFill)
        }
        
        // Notify providers on win/lose
        bids.forEach { bid in
            if bid.adUnit.uid == winner.adUnit.uid {
                bid.provider.notify(
                    opaque: bid.ad,
                    event: .win
                )
            } else {
                bid.provider.notify(
                    opaque: bid.ad,
                    event: .lose(
                        winner.adUnit.demandId,
                        winner.ad,
                        winner.price
                    )
                )
            }
        }
        
        // Auction result is success
        return .success(winner)
    }
}
