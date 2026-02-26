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
        completionLock.lock()
        let alreadyCompleted = didComplete
        completionLock.unlock()
        
        guard !alreadyCompleted else {
            Logger.dAuction(adType, "[BidsFinishOp] main() — already completed")
            return
        }
        Logger.dAuction(adType, "[BidsFinishOp] main() — collecting bids from \(dependencies.count) deps, ad type: \(adType.stringValue)")
        let result = collectAllBids()
        let winner = (try? result.get())?.first
        
        if callCompletion(result), let winner {
            observer.log(FinishAuctionEvent(winner: winner))
        }
    }

    override func cancel() {
        super.cancel()

        if callCompletion(.failure(.cancelled)) {
            Logger.dAuction(adType, "[BidsFinishOp] cancel() called — returning .cancelled (bids not collected)")
            observer.log(CancelAuctionEvent())
        }
    }

    @discardableResult
    private func callCompletion(_ result: Result<[BidType], SdkError>) -> Bool {
        completionLock.lock()

        guard !didComplete else {
            completionLock.unlock()
            return false
        }
        didComplete = true
        completionLock.unlock()
        completion(result)
        
        return true
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
        Logger.dAuction(adType, "[BidsFinishOp] collectAllBids: \(allBids.count) bids [\(prices)], winner=\(winner?.price.debugString ?? "nil")")

        guard !allBids.isEmpty else {
            Logger.dAuction(adType, "[BidsFinishOp] collectAllBids: → .noFill")
            return .failure(.noFill)
        }

        return .success(allBids)
    }
}
