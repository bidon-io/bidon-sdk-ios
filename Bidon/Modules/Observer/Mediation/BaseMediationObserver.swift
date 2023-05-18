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
    var adId: String? = nil
    var status: DemandReportStatus = .unknown
    var eCPM: Price? = nil
    var isRoundWinner: Bool = false
    var isAuctionWinner: Bool = false
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
        let rounds: [RoundReportModel] = roundObservations.map { round in
            let demands = demandObservations
                .filter { $0.roundId == round.roundId }
            
            let winner = demands.first { $0.isRoundWinner }
            
            return RoundReportModel(
                roundId: round.roundId,
                pricefloor: round.pricefloor,
                winnerECPM: winner?.eCPM,
                winnerNetworkId: winner?.networkId,
                demands: demands.map { DemandReportModel($0) }
            )
        }
        
        let winner = demandObservations.first { $0.isAuctionWinner }
        let result = AuctionResultReportModel(
            status: winner != nil ? .success : .fail,
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
    private var demandObservations: [DemandObservation] = []
    
    @Atomic
    private var roundObservations: [RoundObservation] = []
    
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
        case .roundStart(let round, let pricefloor):
            $roundObservations.mutate {
                $0.append(
                    RoundObservation(
                        roundId: round.id,
                        pricefloor: pricefloor
                    )
                )
            }
        case .lineItemNotFound(let round, let adapter):
            $demandObservations.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        status: .error(.noAppropriateAdUnitId)
                    )
                )
            }
        case .unknownAdapter(let round, let adapter):
            $demandObservations.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        status: .error(.unknownAdapter)
                    )
                )
            }
        case .bidRequest(let round, let adapter):
            $demandObservations.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        bidRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                    )
                )
            }
        case .bidError(let round, let adapter, let error):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.status = DemandReportStatus(error)
            }
        case .bidResponse(let round, let adapter, let bid):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.adId = bid.ad.id
                obsevation.eCPM = bid.eCPM
            }
        case .loadRequest(let round, let adapter, let lineItem):
            $demandObservations.mutate {
                $0.append(
                    DemandObservation(
                        networkId: adapter.identifier,
                        roundId: round.id,
                        adUnitId: lineItem.adUnitId,
                        eCPM: lineItem.pricefloor,
                        fillRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
                    )
                )
            }
        case .loadResponse(let round, let adapter, let bid):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.adId = bid.ad.id
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        case .fillRequest(let round, let adapter, _):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.fillRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        case .fillError(let round, let adapter, let error), .loadError(let round, let adapter, let error):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
                obsevation.status = DemandReportStatus(error)
            }
        case .fillResponse(let round, let adapter, _):
            $demandObservations.update(round: round, adapter: adapter) { obsevation in
                obsevation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            }
        
        case .roundFinish(_, let winner):
            $demandObservations.update(bid: winner) { observation in
                observation.isRoundWinner = true
            }
        case .auctionFinish(let winner):
            $demandObservations.update(
                condition: { $0.status.isUnknown }
            ) { observation in
                if observation.adId == winner?.ad.id {
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
        mutation: (inout DemandObservation) -> ()
    ) {
        update(
            condition: { $0.roundId == round.id && $0.networkId == adapter.identifier },
            mutation: mutation
        )
    }
    
    func update(
        bid: (any Bid)?,
        mutation: (inout DemandObservation) -> ()
    ) {
        guard let bid = bid else { return }
        update(
            condition: { $0.adId == bid.ad.id },
            mutation: mutation
        )
    }
}
