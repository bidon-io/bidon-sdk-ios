//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


final class BaseAuctionObserver: AuctionObserver {
    let adType: AdType
    let configuration: AuctionConfiguration

    @Atomic
    private var round: RoundObservation

    @Atomic
    private var startTimestamp: TimeInterval = Date.timestamp(.wall, units: .milliseconds)

    @Atomic
    private var finishTimestamp: TimeInterval = 0

    @Atomic
    private var isCancelled: Bool = false

    init(configuration: AuctionConfiguration, adType: AdType) {
        self.adType = adType
        self.configuration = configuration

        self.round = RoundObservation(
            pricefloor: configuration.pricefloor,
            tokens: configuration.tokens
        )
    }

    func log<EventType>(_ event: EventType) where EventType: AuctionEvent {
        Logger.debug("[\(adType)] [Auction: \(configuration.auctionId)] " + event.description)

        switch event {
            // Auction level
        case let _event as StartAuctionEvent:
            $startTimestamp.wrappedValue = _event.startTimestamp
        case let _event as FinishAuctionEvent:
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $round.mutate { round in
                round.didFinishAuction(_event.winner)
            }
        case _ as CancelAuctionEvent:
            $isCancelled.wrappedValue = true
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $round.mutate { round in
                round.cancel()
            }
//             Demand level
//             Direct demand
        case let _event as DirectDemandErrorAuctionEvent:
            $round.mutate { round in
                round.demand.didFailDemand(_event.adapter.demandId, error: _event.error)
            }
        case let _event as DirectDemandWillLoadAuctionEvent:
            $round.mutate { observation in
                observation.demand.willLoadAdUnit(_event.adUnit)
            }
        case let _event as DirectDemandLoadingErrorAucitonEvent:
            $round.mutate { observation in
                observation.demand.didFailAdUnit(_event.adUnit, error: _event.error)
            }
        case let _event as DirectDemandDidLoadAuctionEvent:
            $round.mutate { observation in
                observation.demand.didReceiveClientBid(_event.bid)
            }
            // Bidding demand
        case let _event as BiddingDemandBidRequestAuctionEvent:
            $round.mutate { observation in
                observation.bidding.willRequestBid()
            }
        case let _event as BiddingDemandBidResponseAuctionEvent:
            $round.mutate { observation in
                observation.bidding.didReceiveServerBids(_event.bids)
            }
        case let _event as BiddingDemandWillLoadAuctionEvent:
            $round.mutate { observation in
                observation.bidding.willLoadAdUnit(_event.adUnit)
            }
        case let _event as BiddingDemandLoadingErrorAucitonEvent:
            $round.mutate { observation in
                observation.bidding.didFailAdUnit(_event.adUnit, error: _event.error)
            }
        case let _event as BiddingDemandDidLoadAuctionEvent:
            $round.mutate { observation in
                observation.bidding.didReceiveClientBid(_event.bid)
            }
        case let _event as BiddingDemandBelowPricefloorAucitonEvent:
            $round.mutate { observation in
                observation.bidding.didFailPricefloor(_event.adUnit)
            }
        case let _event as DirectDemandBelowPricefloorAucitonEvent:
            $round.mutate { observation in
                observation.bidding.didFailPricefloor(_event.adUnit)
            }
        case let _event as AuctionTimeoutEvent:
            $round.mutate { observation in
                observation.bidding.didFailAdUnit(_event.adUnit, error: .fillTimeoutReached)
            }
        default:
            break
        }
    }
}


extension BaseAuctionObserver: AuctionReportProvider {
    private var result: AuctionResultReportModel {
        if isCancelled {
            return AuctionResultReportModel(
                status: .cancelled,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint,
                winner: round.auctionWinner?.bid
            )
        }
        if round.auctionWinner != nil {
            return AuctionResultReportModel(
                status: .success,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint,
                winner: round.auctionWinner?.bid
            )
        }

        return AuctionResultReportModel(
            status: .fail,
            startTimestamp: startTimestamp.uint,
            finishTimestamp: finishTimestamp.uint
        )
    }


    var report: AuctionReportModel {
        let rounds = AuctionRoundReportModel(
            pricefloor: round.pricefloor,
            demands: round.demand.entries.map(AuctionDemandReportModel.init),
            bidding: AuctionRoundBiddingReportModel(demands: round.bidding.entries.map(AuctionDemandReportModel.init))
        )

        return AuctionReportModel(
            configuration: configuration,
            round: rounds,
            result: result
        )
    }
}


fileprivate extension Atomic where Value == Array<RoundObservation> {
    func mutateEach(mutation: (inout RoundObservation) -> ()) {
        mutate { value in
            value = value.map { entry in
                var entry = entry
                mutation(&entry)
                return entry
            }
        }
    }
}
