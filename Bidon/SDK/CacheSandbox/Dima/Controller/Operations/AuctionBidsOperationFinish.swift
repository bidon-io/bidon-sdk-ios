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

    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var completion: ((Result<[BidType], SdkError>) -> ())!

        @discardableResult
        func withCompletion(_ completion: @escaping (Result<[BidType], SdkError>) -> ()) -> Self {
            self.completion = completion
            return self
        }
    }

    let observer: AnyAuctionObserver
    let completion: (Result<[BidType], SdkError>) -> ()
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
        Logger.dAuction("[BidsFinishOp] main() — collecting bids from \(dependencies.count) deps")

        let result = collectAllBids()
        let completion = self.completion

        completion(result)
    }

    override func cancel() {
        super.cancel()
        Logger.dAuction("[BidsFinishOp] cancel() called — returning .cancelled (bids not collected)")

        observer.log(CancelAuctionEvent())
        findWinner()

        let result = Result<[BidType], SdkError>.failure(.cancelled)
        let completion = self.completion
        completion(result)
    }

    private func collectAllBids() -> Result<[BidType], SdkError> {
        let directResults = deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })

        let bidResults = deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })

        let allBids = (directResults + bidResults)
            .sorted { comparator.compare($0, $1) }
            .compactMap { $0 as? BidType }

        let winner = allBids.first
        let prices = allBids.map { String(format: "%.2f", $0.price) }.joined(separator: ", ")
        Logger.dAuction("[BidsFinishOp] collectAllBids: \(allBids.count) bids [\(prices)], winner=\(winner.map { String(format: "%.2f", $0.price) } ?? "nil")")

        observer.log(FinishAuctionEvent(winner: winner))

        guard !allBids.isEmpty else {
            Logger.dAuction("[BidsFinishOp] collectAllBids: → .noFill")
            return .failure(.noFill)
        }

        return .success(allBids)
    }
    
    @discardableResult
    private func findWinner() -> Result<BidType, SdkError> {
        let directResults = deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })
            .sorted { comparator.compare($0, $1) }

        let bidResults = deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
            .compactMap({ $0.bid })
            .sorted { comparator.compare($0, $1) }

        let directWinner = directResults.first
        let bidWinner = bidResults.first

        var result: Result<BidType, SdkError>
        switch (directWinner, bidWinner) {
        case (.none, .none):
            result = .failure(.noFill)
            observer.log(FinishAuctionEvent(winner: nil))
        case (.none, .some(let winner)):
            result = .success(winner as! BidType)
            observer.log(FinishAuctionEvent(winner: winner))

        case (.some(let winner), .none):

            result = .success(winner as! BidType)
            observer.log(FinishAuctionEvent(winner: winner))
        case (.some(let directWrappedWinner), .some(let bidWrappedWinner)):
            let winner = max(directWrappedWinner, bidWrappedWinner)

            result = .success(winner as! BidType)
            observer.log(FinishAuctionEvent(winner: winner))
        }
        return result
    }
}
