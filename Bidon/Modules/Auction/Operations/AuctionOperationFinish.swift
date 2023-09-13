//
//  FinishAuctionOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationFinish<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    let observer: AnyMediationObserver
    let completion: (Result<BidType, SdkError>) -> ()
    let comparator: AuctionBidComparator
    let auctionConfiguration: AuctionConfiguration
    
    init(
        comparator: AuctionBidComparator,
        observer: AnyMediationObserver,
        auctionConfiguration: AuctionConfiguration,
        completion: @escaping (Result<BidType, SdkError>) -> ()
    ) {
        self.auctionConfiguration = auctionConfiguration
        self.observer = observer
        self.comparator = comparator
        self.completion = completion
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        let bids = deps(AuctionOperationFinishRound<AdTypeContextType, BidType>.self)
            .reduce([]) { $0 + $1.bids }
            .sorted { comparator.compare($0, $1) }
        
        let winner = bids.first
        
        observer.log(
            AuctionFinishMediationEvent(bid: winner)
        )
        
        let result = result(for: bids, winner: winner)
        let completion = self.completion
        
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    override func cancel() {
        super.cancel()
        
        observer.log(CancelAuctionMediationEvent())
        
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
            if bid.ad.id == winner.ad.id {
                bid.provider.notify(
                    opaque: bid.ad,
                    event: .win
                )
            } else {
                bid.provider.notify(
                    opaque: bid.ad,
                    event: .lose(winner.ad, winner.eCPM)
                )
            }
        }
        
        // Auction result is success
        return .success(winner)
    }
}


extension AuctionOperationFinish: AuctionOperation {}
