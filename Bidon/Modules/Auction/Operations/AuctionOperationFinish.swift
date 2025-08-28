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
        func withCompletion(_ completion: @escaping (Result<BidType, SdkError>) -> ()) -> Self {
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

        let result = findWinner()
        let completion = self.completion

        completion(result)
    }

    override func cancel() {
        super.cancel()

        observer.log(CancelAuctionEvent())

        findWinner()

        let result = Result<BidType, SdkError>.failure(.cancelled)
        let completion = self.completion
        completion(result)
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
            notifyBids(bidResults, winner: winner)
        case (.some(let winner), .none):
            notifyBids(directResults, winner: winner)
            result = .success(winner as! BidType)
            observer.log(FinishAuctionEvent(winner: winner))
        case (.some(let directWrappedWinner), .some(let bidWrappedWinner)):
            let winner = max(directWrappedWinner, bidWrappedWinner)
            notifyBids(directResults + bidResults, winner: winner)
            result = .success(winner as! BidType)
            observer.log(FinishAuctionEvent(winner: winner))
        }
        return result
    }

    private func notifyBids(
        _ bids: [BidModel<AdTypeContextType.DemandProviderType>],
        winner: BidModel<AdTypeContextType.DemandProviderType>
    ) {
        guard !bids.isEmpty else { return }

        let winnerUID = winner.adUnit.uid
        let losingEvent: DemandProviderEvent = .lose(
            winner.adUnit.demandId,
            winner.ad,
            winner.price
        )

        for bid in bids {
            let isWinner = bid.adUnit.uid == winnerUID
            let shouldNotifyWin  = !auctionConfiguration.isExternalNotificationsEnabled && isWinner && bid.adUnit.bidType == .direct
            let shouldNotifyLose = !isWinner && bid.adUnit.bidType == .direct

            if shouldNotifyWin {
                bid.provider.notify(opaque: bid.ad, event: .win)
                Logger.info("[Win/Loss] Notify \(bid.adUnit.demandId) win")
            } else if isWinner {
                Logger.info("[Win/Loss] Do not notify \(bid.adUnit.demandId) win. Notifications enabled - \(auctionConfiguration.isExternalNotificationsEnabled), bid type - \(bid.adUnit.bidType.rawValue)")
            }

            if shouldNotifyLose {
                bid.provider.notify(opaque: bid.ad, event: losingEvent)
                Logger.info("[Win/Loss] Notify \(bid.adUnit.demandId) lose")
            } else if !isWinner {
                Logger.info("[Win/Loss] Do not notify \(bid.adUnit.demandId) lose. Bid type - \(bid.adUnit.bidType.rawValue)")

            }
        }
    }
}
