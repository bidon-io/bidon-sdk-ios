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
        let prices = allBids.map { $0.price.debugString }.joined(separator: ", ")
        Logger.dAuction("[BidsFinishOp] collectAllBids: \(allBids.count) bids [\(prices)], winner=\(winner?.price.debugString ?? "nil")")

        observer.log(FinishAuctionEvent(winner: winner))

        guard !allBids.isEmpty else {
            Logger.dAuction("[BidsFinishOp] collectAllBids: → .noFill")
            return .failure(.noFill)
        }

        return .success(allBids)
    }
}
