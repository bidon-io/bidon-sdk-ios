//
//  MediationObserver.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


fileprivate struct DemandObservation {
    var networkId: String
    var roundId: String
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
    let auctionId: String
    let auctionConfigurationId: Int
    let adType: AdType
    
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
                bidding: demands.filter { $0.isBidding }.map { DemandReportModel($0) }
            )
        }
        
        let winner = demands.first { $0.isAuctionWinner }
        let result = AuctionResultReportModel(
            status: winner != nil ? .success : .fail,
            startTimestamp: startTimestamp.uint,
            finishTimestamp: finishTimestamp.uint,
            winnerNetworkId: winner?.networkId,
            winnerECPM: winner?.eCPM,
            winnerAdUnitId: winner?.adUnitId
        )
        
        return MediationAttemptReportModel(
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
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
    
    init(
        auctionId id: String,
        auctionConfigurationId configurationId: Int,
        adType: AdType
    ) {
        self.adType = adType
        self.auctionId = id
        self.auctionConfigurationId = configurationId
    }
    
    func log(_ event: MediationEvent) {
        Logger.debug("[\(adType)] [Auction: \(auctionId)] " + event.description)
        
        switch event {
        case .auctionStart:
            startTimestamp = Date.timestamp(.wall, units: .milliseconds)
        case .roundStart(let round, let pricefloor):
            $rounds.mutate {
                $0.append(
                    RoundObservation(
                        roundId: round.id,
                        pricefloor: pricefloor
                    )
                )
            }
        case .lineItemNotFound(let round, let adapter):
            $demands.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        status: .error(.noAppropriateAdUnitId),
                        isBidding: false
                    )
                )
            }
        case .unknownAdapter(let round, let adapter):
            $demands.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        status: .error(.unknownAdapter),
                        isBidding: false
                    )
                )
            }
        case .bidRequest(let round, let adapter, let isBidding):
            $demands.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        isBidding: isBidding,
                        bidRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                    )
                )
            }
        case .bidError(let round, let adapter, let error, let isBidding):
            $demands.update(
                round: round,
                adapter: adapter,
                isBidding: isBidding
            ) { obsevation in
                obsevation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.status = DemandReportStatus(error)
            }
        case .bidResponse(let round, let adapter, let bid, let isBidding):
            $demands.update(
                round: round,
                adapter: adapter,
                isBidding: isBidding
            ) { obsevation in
                obsevation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.bidId = bid.id
                obsevation.eCPM = bid.eCPM
            }
        case .loadRequest(let round, let adapter, let lineItem):
            $demands.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        adUnitId: lineItem.adUnitId,
                        eCPM: lineItem.pricefloor,
                        isBidding: false,
                        fillRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                    )
                )
            }
        case .loadResponse(let round, let adapter, let bid):
            $demands.update(
                round: round,
                adapter: adapter
            ) { obsevation in
                obsevation.bidId = bid.id
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        case .fillRequest(let round, let adapter, _, let isBidding):
            $demands.update(
                round: round,
                adapter: adapter,
                isBidding: isBidding
            ) { obsevation in
                obsevation.fillRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        case .fillError(let round, let adapter, let error, let isBidding):
            $demands.update(
                round: round,
                adapter: adapter,
                isBidding: isBidding
            ) { obsevation in
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.status = DemandReportStatus(error)
            }
        case .loadError(let round, let adapter, let error):
            $demands.update(
                round: round,
                adapter: adapter
            ) { obsevation in
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.status = DemandReportStatus(error)
            }
        case .fillResponse(let round, let adapter, _, let isBidding):
            $demands.update(
                round: round,
                adapter: adapter,
                isBidding: isBidding
            ) { obsevation in
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        case .roundFinish(_, let winner):
            $demands.update(bid: winner) { observation in
                observation.isRoundWinner = true
            }
        case .auctionFinish(let winner):
            finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
            $demands.update(
                condition: { $0.status.isUnknown }
            ) { observation in
                if observation.bidId == winner?.id {
                    observation.status = .win
                    observation.isAuctionWinner = true
                } else {
                    observation.status = .lose
                }
            }
        default:
            break
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
        adapter: Adapter,
        isBidding: Bool = false,
        mutation: (inout DemandObservation) -> ()
    ) {
        update(
            condition: { $0.roundId == round.id && $0.networkId == adapter.identifier && ($0.isBidding == isBidding) },
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
