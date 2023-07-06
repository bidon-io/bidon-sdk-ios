//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


fileprivate struct DemandObservation {
    var roundId: String
    var networkId: String?
    var adUnitId: String?
    var bidId: String? = nil
    var status: DemandReportStatus = .unknown
    var eCPM: Price? = nil
    var isRoundWinner: Bool = false
    var isAuctionWinner: Bool = false
    var isBidding: Bool
    var bidRequestTimestamp: TimeInterval?
    var bidResponeTimestamp: TimeInterval?
    var fillRequestTimestamp: TimeInterval?
    var fillResponseTimestamp: TimeInterval?
}


fileprivate struct RoundObservation {
    var roundId: String
    var pricefloor: Price
}


final class BaseMediationObserver: MediationObserver {
    let adType: AdType
    let auctionId: String
    
    var report: MediationAttemptReportModel {
        let rounds: [RoundReportModel] = rounds.map { round in
            let demands = demands
                .filter { $0.roundId == round.roundId }
            
            let winner = demands.first { $0.isRoundWinner }
            
            return RoundReportModel(
                roundId: round.roundId,
                pricefloor: round.pricefloor,
                winnerECPM: winner?.eCPM,
                winnerNetworkId: winner?.networkId,
                demands: demands.filter { !$0.isBidding }.map { DemandReportModel($0) },
                bidding: demands.first { $0.isBidding }.map { DemandReportModel($0) }
            )
        }
        
        let winner = demands.first { $0.isAuctionWinner }
        let status = AuctionResultReportStatus(
            hasWinner: winner != nil,
            isCancelled: isCancelled
        )
        
        let result = AuctionResultReportModel(
            status: status,
            startTimestamp: startTimestamp.uint,
            finishTimestamp: finishTimestamp.uint,
            winnerNetworkId: winner?.networkId,
            winnerECPM: winner?.eCPM,
            winnerAdUnitId: winner?.adUnitId
        )
        
        return MediationAttemptReportModel(
            rounds: rounds,
            result: result
        )
    }
    
    @Atomic
    private var demands: [DemandObservation] = []
    
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
        case let _event as AuctionStartMediationEvent:
            recordAuctionStartMediationEvent(_event)
        case let _event as AuctionFinishMediationEvent:
            recordAuctionFinishMediationEvent(_event)
        // Round level
        case let _event as RoundStartMediationEvent:
            recordRoundStartMediationEvent(_event)
        case let _event as RoundFinishMediationEvent:
            recordRoundFinishMediationEvent(_event)
        // Abstract demand level
        case let _event as DemandProviderNotFoundMediationEvent:
            recordDemandProviderNotFoundMediationEvent(_event)
        // Direct demand level
        case let _event as DirectDemandProviderLineItemNotFoundMediationEvent:
            recordDirectDemandProviderLineItemNotFoundMediationEvent(_event)
        case let _event as DirectDemandProividerLoadRequestMediationEvent:
            recordDirectDemandProividerLoadRequestMediationEvent(_event)
        case let _event as DirectDemandProividerDidFailToLoadMediationEvent:
            recordDirectDemandProividerDidFailToLoadMediationEvent(_event)
        case let _event as DirectDemandProividerDidLoadMediationEvent:
            recordDirectDemandProividerDidLoadMediationEvent(_event)
        // Programmatic demand level
        case let _event as ProgrammaticDemandProviderRequestBidMediationEvent:
            recordProgrammaticDemandProviderRequestBidMediationEvent(_event)
        case let _event as ProgrammaticDemandProviderBidErrorMediationEvent:
            recordProgrammaticDemandProviderBidErrorMediationEvent(_event)
        case let _event as ProgrammaticDemandProviderDidReceiveBidMediationEvent:
            recordProgrammaticDemandProviderDidReceiveBidMediationEvent(_event)
        case let _event as ProgrammaticDemandProviderRequestFillMediationEvent:
            recordProgrammaticDemandProviderRequestFillMediationEvent(_event)
        case let _event as ProgrammaticDemandProviderDidFailToFillBidMediationEvent:
            recordProgrammaticDemandProviderDidFailToFillBidMediationEvent(_event)
        case let _event as ProgrammaticDemandProviderDidFillBidMediationEvent:
            recordProgrammaticDemandProviderDidFillBidMediationEvent(_event)
        // Bidding demand level
        case let _event as BiddingDemandProviderRequestBidMediationEvent:
            recordBiddingDemandProviderRequestBidMediationEvent(_event)
        case let _event as BiddingDemandProviderBidErrorMediationEvent:
            recordBiddingDemandProviderBidErrorMediationEvent(_event)
        case let _event as BiddingDemandProviderFillRequestMediationEvent:
            recordBiddingDemandProviderFillRequestMediationEvent(_event)
        case let _event as BiddingDemandProviderFillErrorMediationEvent:
            recordBiddingDemandProviderFillErrorMediationEvent(_event)
        case let _event as BiddingDemandProviderDidFillMediationEvent:
            recordBiddingDemandProviderDidFillMediationEvent(_event)
        case let _event as CancelAuctionMediationEvent:
            recordCancelAuctionMediationEvent(_event)
        default:
            break
        }
    }
}

private extension BaseMediationObserver {
    // MARK: Auction Events
    func recordAuctionStartMediationEvent(_ event: AuctionStartMediationEvent) {
        $startTimestamp.mutate { $0 = Date.timestamp(.wall, units: .milliseconds) }
    }
    
    func recordAuctionFinishMediationEvent(_ event: AuctionFinishMediationEvent) {
        $finishTimestamp.mutate { $0 = Date.timestamp(.wall, units: .milliseconds) }
        $demands.update(
            condition: { $0.status.isUnknown }
        ) { observation in
            if observation.bidId == event.bid?.id {
                observation.status = .win
                observation.isAuctionWinner = true
            } else {
                observation.status = .lose
            }
        }
    }
    
    // MARK: Round Events
    func recordRoundStartMediationEvent(_ event: RoundStartMediationEvent) {
        $rounds.mutate {
            $0.append(
                RoundObservation(
                    roundId: event.round.id,
                    pricefloor: event.pricefloor
                )
            )
        }
    }
    
    private func recordRoundFinishMediationEvent(_ event: RoundFinishMediationEvent) {
        $demands.update(bid: event.bid) { observation in
            observation.isRoundWinner = true
        }
    }
    
    // MARK: Abstract Demand Provider Events
    func recordDemandProviderNotFoundMediationEvent(_ event: DemandProviderNotFoundMediationEvent) {
        $demands.mutate {
            $0.append(
                DemandObservation(
                    roundId: event.round.id,
                    networkId: event.adapter.identifier,
                    status: .error(.unknownAdapter),
                    isBidding: false
                )
            )
        }
    }
    
    // MARK: Direct Demand Provider Events
    func recordDirectDemandProviderLineItemNotFoundMediationEvent(_ event: DirectDemandProviderLineItemNotFoundMediationEvent) {
        $demands.mutate {
            $0.append(
                DemandObservation(
                    roundId: event.round.id,
                    networkId: event.adapter.identifier,
                    status: .error(.noAppropriateAdUnitId),
                    isBidding: false
                )
            )
        }
    }
    
    func recordDirectDemandProividerLoadRequestMediationEvent(_ event: DirectDemandProividerLoadRequestMediationEvent) {
        $demands.mutate {
            $0.append(
                DemandObservation(
                    roundId: event.round.id,
                    networkId: event.adapter.identifier,
                    adUnitId: event.lineItem.adUnitId,
                    eCPM: event.lineItem.pricefloor,
                    isBidding: false,
                    fillRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                )
            )
        }
    }
    
    func recordDirectDemandProividerDidFailToLoadMediationEvent(_ event: DirectDemandProividerDidFailToLoadMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter
        ) { observation in
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = DemandReportStatus(event.error)
        }
    }
    
    func recordDirectDemandProividerDidLoadMediationEvent(_ event: DirectDemandProividerDidLoadMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter
        ) { observation in
            observation.bidId = event.bid.id
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
        }
    }
    
    // MARK: Programmatic Demand Provider Events
    func recordProgrammaticDemandProviderRequestBidMediationEvent(_ event: ProgrammaticDemandProviderRequestBidMediationEvent) {
        $demands.mutate {
            $0.append(
                DemandObservation(
                    roundId: event.round.id,
                    networkId: event.adapter.identifier,
                    isBidding: false,
                    bidRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                )
            )
        }
    }
    
    func recordProgrammaticDemandProviderBidErrorMediationEvent(_ event: ProgrammaticDemandProviderBidErrorMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter,
            isBidding: false
        ) { observation in
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = DemandReportStatus(event.error)
        }
    }
    
    private func recordProgrammaticDemandProviderDidReceiveBidMediationEvent(_ event: ProgrammaticDemandProviderDidReceiveBidMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter,
            isBidding: false
        ) { observation in
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.bidId = event.bid.id
            observation.eCPM = event.bid.eCPM
        }
    }
    
    func recordProgrammaticDemandProviderRequestFillMediationEvent(_ event: ProgrammaticDemandProviderRequestFillMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter,
            isBidding: false
        ) { observation in
            observation.fillRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
        }
    }
    
    func recordProgrammaticDemandProviderDidFailToFillBidMediationEvent(_ event: ProgrammaticDemandProviderDidFailToFillBidMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter,
            isBidding: false
        ) { observation in
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = DemandReportStatus(event.error)
        }
    }
    
    func recordProgrammaticDemandProviderDidFillBidMediationEvent(_ event: ProgrammaticDemandProviderDidFillBidMediationEvent) {
        $demands.update(
            round: event.round,
            adapter: event.adapter,
            isBidding: false
        ) { observation in
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
        }
    }
    
    // MARK: Bidding Demand Provider Events
    func recordBiddingDemandProviderRequestBidMediationEvent(_ event: BiddingDemandProviderRequestBidMediationEvent) {
        $demands.mutate {
            $0.append(
                DemandObservation(
                    roundId: event.round.id,
                    isBidding: true,
                    bidRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                )
            )
        }
    }
    
    func recordBiddingDemandProviderBidErrorMediationEvent(_ event: BiddingDemandProviderBidErrorMediationEvent) {
        $demands.update(
            round: event.round,
            isBidding: true
        ) { observation in
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = DemandReportStatus(event.error)
        }
    }

    func recordBiddingDemandProviderFillRequestMediationEvent(_ event: BiddingDemandProviderFillRequestMediationEvent) {
        $demands.update(
            round: event.round,
            isBidding: true
        ) { observation in
            observation.networkId = event.adapter.identifier
            observation.eCPM = event.bid.price
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.fillRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
        }
    }

    func recordBiddingDemandProviderFillErrorMediationEvent(_ event: BiddingDemandProviderFillErrorMediationEvent) {
        $demands.update(
            round: event.round,
            isBidding: true
        ) { observation in
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = DemandReportStatus(event.error)
        }
    }

    func recordBiddingDemandProviderDidFillMediationEvent(_ event: BiddingDemandProviderDidFillMediationEvent) {
        $demands.update(
            round: event.round,
            isBidding: true
        ) { observation in
            observation.bidId = event.bid.id
            observation.eCPM = event.bid.eCPM
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
        }
    }
    
    func recordCancelAuctionMediationEvent(_ event: CancelAuctionMediationEvent) {
        $isCancelled.mutate { $0 = true }
        $finishTimestamp.mutate { $0 = Date.timestamp(.wall, units: .milliseconds) }
        $demands.update(
            condition: { $0.status.isUnknown }
        ) { observation in
            observation.bidRequestTimestamp = nil
            observation.bidResponeTimestamp = nil
            observation.fillRequestTimestamp = nil
            observation.fillResponseTimestamp = nil
            observation.status = .error(.auctionCancelled)
        }
    }
}


private extension DemandReportModel {
    init(_ observation: DemandObservation) {
        self.networkId = observation.networkId
        self.adUnitId = observation.adUnitId
        self.eCPM = observation.eCPM
        self.status = observation.status
        self.bidStartTimestamp = observation.bidRequestTimestamp?.uint
        self.bidFinishTimestamp = observation.bidResponeTimestamp?.uint
        self.fillStartTimestamp = observation.fillRequestTimestamp?.uint
        self.fillFinishTimestamp = observation.fillResponseTimestamp?.uint
    }
}


private extension Atomic where Value == [DemandObservation] {
    func update(
        condition: (DemandObservation) -> Bool,
        mutation: (inout DemandObservation) -> ()
    ) {
        mutate { value in
            value = value.map { element in
                guard condition(element) else { return element }
                var element = element
                mutation(&element)
                return element
            }
        }
    }
    
    func update(
        round: AuctionRound,
        adapter: Adapter? = nil,
        isBidding: Bool = false,
        mutation: (inout DemandObservation) -> ()
    ) {
        update(
            condition: {
                let isSameRound = $0.roundId == round.id
                let isSameDemand = $0.networkId == adapter?.identifier && !$0.isBidding && !isBidding
                let isBidding = $0.isBidding && isBidding
                // Same round and network (demand) id same
                // or is bidding demand. Bidding demand should
                // be only one per a round
                return isSameRound && (isSameDemand || isBidding)
            },
            mutation: mutation
        )
    }
    
    func update(
        bid: (any Bid)?,
        mutation: (inout DemandObservation) -> ()
    ) {
        guard let bid = bid else { return }
        update(
            condition: { $0.bidId == bid.id },
            mutation: mutation
        )
    }
}


private extension AuctionResultReportStatus {
    init(hasWinner: Bool, isCancelled: Bool) {
        switch (hasWinner, isCancelled) {
        case (true, false):     self = .success
        case (false, false):    self = .fail
        case (_, true):         self = .cancelled
        }
    }
}
