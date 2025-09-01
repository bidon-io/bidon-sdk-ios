//
//  DemandsTokensManager.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 24/05/2024.
//

import Foundation

final class DemandsTokensManager<AdTypeContextType: AdTypeContext> {

    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>
    typealias BuilderType = DemandsTokensManagerBuilder<AdTypeContextType>

    private let context: AdTypeContextType
    private var adapters: [AdapterType]
    private let demands: [String]
    private let timeout: TimeInterval
    private let auctionKey: String?
    private let adaptersRepository: AdaptersRepository

    private var tokens = [BiddingDemandToken]()
    private var biddingDemadIds = [String]()
    private var startTimestamp: TimeInterval?
    private var isTimeoutReached = false

    private let group = DispatchGroup()
    private let lock = NSRecursiveLock()


    init(builder: BuilderType) {
        self.adapters = builder.adapters
        self.demands = builder.demands
        self.timeout = builder.timeout / 1000
        self.context = builder.context
        self.auctionKey = builder.auctionKey
        self.adaptersRepository = builder.adaptersRepository
    }

    func load(
        initializationParameters: AdaptersInitialisationParameters,
        completion: @escaping ((Result<[BiddingDemandToken], Error>) -> Void)
    ) {
        let initializedIds = adaptersRepository.initializedIds
        let filteredAdapters = adapters.filter { adapter in
            demands.contains(adapter.demandId)
            && adapter.provider is (any GenericBiddingDemandProvider)
            && initializedIds.contains(adapter.demandId)
        }
        biddingDemadIds = filteredAdapters.map({ $0.demandId })

        startTimestamp = Date.timestamp(.wall, units: .milliseconds)
        for adapter in filteredAdapters {
            if let provider = adapter.provider as? any GenericBiddingDemandProvider,
               let parameters = initializationParameters.adapters.first(where: { $0.demandId == adapter.demandId }) {

                group.enter()
                getTokenFromProvider(
                    provider,
                    demandId: adapter.demandId,
                    auctionKey: auctionKey,
                    startTimestamp: startTimestamp ?? Date.timestamp(.wall, units: .milliseconds),
                    parameters: parameters) { [weak self] demandToken in
                        guard let self else { return }
                        lock.lock()
                        tokens.append(demandToken)
                        group.leave()
                        lock.unlock()
                    }

            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self, !isTimeoutReached else { return }
            isTimeoutReached = true

            completion(.success(tokens))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self, !isTimeoutReached else { return }
            isTimeoutReached = true

            let notReachedDemandTokens = getNotReachedDemandTokens()
            let tempDemandTokens = tokens + notReachedDemandTokens

            completion(.success(tempDemandTokens))
        }

    }


    // MARK: Private functions
    private func getTokenFromProvider(
        _ provider: any GenericBiddingDemandProvider,
        demandId: String,
        auctionKey: String?,
        startTimestamp: TimeInterval,
        parameters: AdaptersInitialisationParameters.AdapterConfiguration,
        completion: @escaping (BiddingDemandToken) -> Void) {
            provider.collectBiddingTokenEncoder(auctionKey: auctionKey, adUnitExtrasDecoder: parameters.decoder) { result in

                let finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
                switch result {
                case .success(let token):
                    let demandToken = BiddingDemandToken(
                        demandId: demandId,
                        token: token,
                        tokenStartTs: startTimestamp.uint,
                        tokenFinishTs: finishTimestamp.uint,
                        status: .success
                    )
                    completion(demandToken)

                case .failure:
                    let demandToken = BiddingDemandToken(
                        demandId: demandId,
                        token: nil,
                        tokenStartTs: startTimestamp.uint,
                        tokenFinishTs: finishTimestamp.uint,
                        status: .noToken
                    )
                    completion(demandToken)

                }
            }
        }


    private func getNotReachedDemandTokens() -> [BiddingDemandToken] {
        let reachedDemandsIds = tokens.map { $0.demandId }
        let notReachedDemandIds = biddingDemadIds.filter { !reachedDemandsIds.contains($0) }

        let finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
        let emptyBiddingDemandTokens = notReachedDemandIds.compactMap { demandId in
            BiddingDemandToken(
                demandId: demandId,
                token: nil,
                tokenStartTs: startTimestamp?.uint ?? finishTimestamp.uint,
                tokenFinishTs: finishTimestamp.uint,
                status: .timeout
            )
        }
        return emptyBiddingDemandTokens
    }

}
