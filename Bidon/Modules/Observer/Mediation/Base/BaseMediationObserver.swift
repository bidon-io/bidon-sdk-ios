//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation

final class BaseMediationObserver: MediationObserver {
    let adType: AdType
    let auctionId: String
    
    @Atomic
    private var rounds: [RoundObservation] = []
    
    @Atomic
    private var startTimestamp: TimeInterval = 0
    
    @Atomic
    private var finishTimestamp: TimeInterval = 0
    
    @Atomic
    private var isCancelled: Bool = false
    
    init(auctionId: String, adType: AdType) {
        self.adType = adType
        self.auctionId = auctionId
    }
    
    func log<EventType>(_ event: EventType) where EventType : MediationEvent {
        Logger.debug("[\(adType)] [Auction: \(auctionId)] " + event.description)
        
        switch event {
            // Auction level
        case _ as AuctionStartMediationEvent:
            $startTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
        case let _event as AuctionFinishMediationEvent:
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $rounds.mutateEach { observation in
                observation.finishAuctionObservation(_event.bid)
            }
            // Round level
        case let _event as RoundStartMediationEvent:
            $rounds.mutate { observation in
                observation.append(
                    RoundObservation(
                        id: _event.roundConfiguration.roundId,
                        pricefloor: _event.pricefloor
                    )
                )
            }
        case let _event as RoundFinishMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.finishObservation(_event.bid)
            }
            // Abstract demand level
        case let _event as DemandProviderNotFoundMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.providerNotFound(_event.adapter)
            }
            // Direct demand level
        case let _event as DirectDemandProviderLineItemNotFoundMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.lineItemNotFound(_event.adapter)
            }
        case let _event as DirectDemandProividerLoadRequestMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.willLoad(_event.adapter, lineItem: _event.lineItem)
            }
        case let _event as DirectDemandProividerDidFailToLoadMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didLoadFail(_event.adapter, error: _event.error)
            }
        case let _event as DirectDemandProividerDidLoadMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didLoadSuccess(_event.adapter, bid: _event.bid)
            }
            // Programmatic demand level
        case let _event as ProgrammaticDemandProviderRequestBidMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.willRequestBid(_event.adapter)
            }
        case let _event as ProgrammaticDemandProviderBidErrorMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didRequestBidFail(_event.adapter, error: _event.error)
            }
        case let _event as ProgrammaticDemandProviderDidReceiveBidMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didReceiveBid(_event.adapter, bid: _event.bid)
            }
        case let _event as ProgrammaticDemandProviderRequestFillMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.willFillBid(_event.adapter, bid: _event.bid)
            }
        case let _event as ProgrammaticDemandProviderDidFailToFillBidMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didFillBidFail(_event.adapter, error: _event.error)
            }
        case let _event as ProgrammaticDemandProviderDidFillBidMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.demand.didFillBidSuccess(_event.adapter, bid: _event.bid)
            }
            // Bidding demand level
        case let _event as BiddingDemandProviderRequestBidMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.willRequestBid()
            }
        case let _event as BiddingDemandProviderBidResponseMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.didRequestBidSuccess(_event.bids)
            }
        case let _event as BiddingDemandProviderBidErrorMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.didRequestBidFail(_event.error)
            }
        case let _event as BiddingDemandProviderFillRequestMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.willFillBid(_event.adapter, bid: _event.bid)
            }
        case let _event as BiddingDemandProviderFillErrorMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.didFillBidFail(_event.adapter, error: _event.error)
            }
        case let _event as BiddingDemandProviderDidFillMediationEvent:
            $rounds.mutate(_event.roundConfiguration.roundId) { observation in
                observation.bidding.didFillBidSuccess(_event.adapter, bid: _event.bid)
            }
        case _ as CancelAuctionMediationEvent:
            $isCancelled.wrappedValue = true
            $finishTimestamp.wrappedValue = Date.timestamp(.wall, units: .milliseconds)
            $rounds.mutateEach { observation in
                observation.cancelObservation()
            }
        default:
            break
        }
    }
}


extension BaseMediationObserver: MediationReportProvider {
    private var result: AuctionResultReportModel {
        guard !isCancelled else {
            return AuctionResultReportModel(
                status: .cancelled,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint
            )
        }
        
        guard let winner = rounds.first(where: { $0.isAuctionWinner }) else {
            return AuctionResultReportModel(
                status: .fail,
                startTimestamp: startTimestamp.uint,
                finishTimestamp: finishTimestamp.uint
            )
        }
        
        return AuctionResultReportModel(
            status: .success,
            demandType: winner.auctionWinner?.demandType?.stringValue,
            startTimestamp: startTimestamp.uint,
            finishTimestamp: finishTimestamp.uint,
            winnerRoundId: winner.id,
            winnerDemandId: winner.auctionWinner?.demandId,
            winnerECPM: winner.auctionWinner?.eCPM,
            winnerAdUnitId: winner.auctionWinner?.adUnitId,
            winnerLineItemUid: winner.auctionWinner?.lineItemUid
        )
    }
    
    var report: MediationAttemptReportModel {
        let rounds = rounds.map(RoundReportModel.init)
        
        return MediationAttemptReportModel(
            rounds: rounds,
            result: result
        )
    }
}
