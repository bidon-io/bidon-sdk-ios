//
//  AuctionBidsOperationFinish.swift
//  Bidon
//
//  Created by Bidon Team on 2024.
//

import Foundation

final class AuctionBidsOperationFinish<
    AdTypeContextType: AdTypeContext,
    BidType: Bid
>: Operation, AuctionOperation where BidType.ProviderType == AdTypeContextType.DemandProviderType, BidType.DemandAdType: DemandAd {
    typealias BuilderType = Builder
    typealias Winner = BidModel<AdTypeContextType.DemandProviderType>

    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var completion: ((Result<[BidType], SdkError>) -> ())!

        @discardableResult
        func withCompletion(_ completion: @escaping (Result<[BidType], SdkError>) -> ()) -> Self {
            self.completion = completion
            return self
        }
    }

    let observer: AnyAuctionObserver
    let comparator: AuctionBidComparator
    let auctionConfiguration: AuctionConfiguration

    private let completion: (Result<[BidType], SdkError>) -> ()
    private let completionLock = NSLock()

    private var didComplete = false
    private var adType: AdType

    init(builder: Builder) {
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        self.comparator = builder.comparator
        self.completion = builder.completion
        self.adType = builder.context.adType

        super.init()
    }

    override func main() {
        guard isCancelled == false else {
            return
        }

        guard markCompleted() else {
            Logger.dAuction(adType, "[BidsFinishOp] main() — already completed")
            return
        }

        Logger.dAuction(adType, "[BidsFinishOp] main() — collecting bids from \(dependencies.count) deps, ad type: \(adType.stringValue)")

        let result = collectAllBids()
        completion(result)
    }

    override func cancel() {
        super.cancel()

        guard markCompleted() else {
            Logger.dAuction(adType, "[BidsFinishOp] cancel() called — already completed")
            return
        }

        observer.log(CancelAuctionEvent())
        _ = collectAllBids()
        completion(.failure(.cancelled))

        Logger.dAuction(
            adType,
            "[BidsFinishOp] cancel() called — returning .cancelled (bids collected for statuses)"
        )
    }

    private func collectAllBids() -> Result<[BidType], SdkError> {
        let directResults = deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })
            .sorted { comparator.compare($0, $1) }

        let bidResults = deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })
            .sorted { comparator.compare($0, $1) }

        let allBids = (directResults + bidResults)
            .compactMap { $0 as? BidType }
            .sorted { comparator.compare($0, $1) }
  
        let directWinner = directResults.first
        let bidWinner = bidResults.first

        let prices = allBids.map { $0.price.debugString }.joined(separator: ", ")
        var auctionWinner: Winner?
        
        var result: Result<[BidType], SdkError>
        switch (directWinner, bidWinner) {
        case (.none, .none):
            result = .failure(.noFill)
            
        case let (.none, .some(winner)):
            result = .success(allBids)
            auctionWinner = winner
            
            notifyBids(bidResults, winner: winner)
            
        case let (.some(winner), .none):
            result = .success(allBids)
            auctionWinner = winner
            
            notifyBids(directResults, winner: winner)
            
        case let (.some(directWrappedWinner), .some(bidWrappedWinner)):
            let winner = max(directWrappedWinner, bidWrappedWinner)
            auctionWinner = winner
            result = .success(allBids)
            
            notifyBids(directResults + bidResults, winner: winner)
        }
        
        observer.log(
            FinishAuctionEvent(winner: auctionWinner)
        )
        Logger.dAuction(adType, "[BidsFinishOp] collectAllBids: \(allBids.count) bids [\(prices)], winner=\(auctionWinner?.price.debugString ?? "nil")")
        return result
    }
    
    private func markCompleted() -> Bool {
        completionLock.lock()
        defer { completionLock.unlock() }

        if didComplete {
            return false
        }
        didComplete = true
        return true
    }

    private func notifyBids(_ bids: [Winner], winner: Winner) {
        // NO-OP
    }
}
