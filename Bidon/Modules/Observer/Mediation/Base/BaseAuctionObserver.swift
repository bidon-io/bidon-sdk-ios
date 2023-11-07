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
    private var rounds: [RoundObservation] = []
    
    @Atomic
    private var startTimestamp: TimeInterval = 0
    
    @Atomic
    private var finishTimestamp: TimeInterval = 0
    
    @Atomic
    private var isCancelled: Bool = false
    
    init(configuration: AuctionConfiguration, adType: AdType) {
        self.adType = adType
        self.configuration = configuration
    }
    
    func log<EventType>(_ event: EventType) where EventType : AuctionEvent {
        Logger.debug("[\(adType)] [Auction: \(configuration.auctionId)] " + event.description)
        
        switch event {
            // Auction level
        case _ as StartAuctionEvent:
            $startTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
        case let _event as FinishAuctionEvent:
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $rounds.mutateEach { round in
                round.didFinishAuction(_event.winner)
            }
        case _ as CancelAuctionEvent:
            $isCancelled.wrappedValue = true
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $rounds.mutateEach { round in
                round.cancel()
            }
            // Round level
        case let _event as StartRoundAuctionEvent:
            $rounds.mutate { observation in
                observation.append(
                    RoundObservation(
                        configuration: _event.configuration,
                        pricefloor: _event.pricefloor
                    )
                )
            }
        case let _event as FinishRoundAuctionEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.didFinishAuctionRound(_event.bid)
            }
            // Demand level
            // Direct demand
        case let _event as DirectDemandErrorAuctionEvent:
            $rounds.mutate(_event.configuration) { round in
                round.demand.didFailDemand(_event.adapter.demandId, error: _event.error)
            }
        case let _event as DirectDemandWillLoadAuctionEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.demand.willLoadAdUnit(_event.adUnit)
            }
        case let _event as DirectDemandLoadingErrorAucitonEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.demand.didFailAdUnit(_event.adUnit, error: _event.error)
            }
        case let _event as DirectDemandDidLoadAuctionEvent:
            $rounds.mutate(_event.bid.roundConfiguration) { observation in
                observation.demand.didReceiveClientBid(_event.bid)
            }
            // Bidding demand
        case let _event as BiddingDemandBidRequestAuctionEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.bidding.willRequestBid()
            }
        case let _event as BiddingDemandBidResponseAuctionEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.bidding.didReceiveServerBids(_event.bids)
            }
        case let _event as BiddingDemandWillLoadAuctionEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.bidding.willLoadAdUnit(_event.bid.adUnit)
            }
        case let _event as BiddingDemandLoadingErrorAucitonEvent:
            $rounds.mutate(_event.configuration) { observation in
                observation.bidding.didFailAdUnit(_event.bid.adUnit, error: _event.error)
            }
        case let _event as BiddingDemandDidLoadAuctionEvent:
            $rounds.mutate(_event.bid.roundConfiguration) { observation in
                observation.bidding.didReceiveClientBid(_event.bid)
            }
        default:
            break
        }
    }
}


extension BaseAuctionObserver: AuctionReportProvider {
    private var result: AuctionResultReportModel {
        guard !isCancelled else {
            return AuctionResultReportModel(
                status: .cancelled,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint
            )
        }
        
        guard let round = rounds.first(where: { $0.isAuctionWinner }) else {
            return AuctionResultReportModel(
                status: .fail,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint
            )
        }
        
        return AuctionResultReportModel(
            status: .success,
            startTimestamp: startTimestamp.uint,
            finishTimestamp: finishTimestamp.uint,
            winnerRoundConfiguration: round.configuration,
            winner: round.auctionWinner?.bid
        )
    }
    
    
    var report: AuctionReportModel {
        let rounds = rounds.map { observation in
            AuctionRoundReportModel(
                configuration: observation.configuration,
                pricefloor: observation.pricefloor,
                demands: observation.demand.entries.map(AuctionDemandReportModel.init),
                bidding: AuctionRoundBiddingReportModel(observation: observation.bidding)
            )
        }
        
        return AuctionReportModel(
            configuration: configuration,
            rounds: rounds,
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
    
    func mutate(
        _ roundConfiguration: AuctionRoundConfiguration,
        mutation: (inout RoundObservation) -> ()
    ) {
        mutate { value in
            value = value.map { entry in
                var entry = entry
                if entry.configuration == roundConfiguration {
                    mutation(&entry)
                }
                return entry
            }
        }
    }
}
