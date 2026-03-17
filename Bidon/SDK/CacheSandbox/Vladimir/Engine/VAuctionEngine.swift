//
//  VAuctionEngine.swift
//  Bidon
//

import Foundation

final class VAuctionEngine<AdTypeContextType: AdTypeContext> {
    typealias AuctionControllerType = VAuctionController<AdTypeContextType>
    typealias BidType = BidModel<AdTypeContextType.DemandProviderType>

    typealias BidLoadCompletion = (BidType, AuctionConfiguration) -> Void
    typealias Report = any AuctionReport
    typealias Completion = (Report?) -> Void
    typealias AuctionFactory = (DefaultAdUnitProvider, BaseAuctionObserver, AuctionConfiguration) -> AuctionControllerType

    @Injected(\.networkManager)
    private var networkManager: NetworkManager

    var onAuctionResponse: ((AuctionRequest.ResponseBody) -> Void)?
    var onBidLoaded: BidLoadCompletion?
    var onComplete: Completion?

    private let context: AdTypeContextType
    private let adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]
    private let sdk: Sdk
    private let extras: [String: AnyHashable]
    private let adRevenueObserver: AdRevenueObserver
    private let buildAuction: AuctionFactory

    private var demandsManager: DemandsTokensManager<AdTypeContextType>?
    private var auction: AuctionControllerType?

    init(
        context: AdTypeContextType,
        adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>],
        sdk: Sdk,
        extras: [String: AnyHashable],
        adRevenueObserver: AdRevenueObserver,
        buildAuction: @escaping AuctionFactory
    ) {
        self.context = context
        self.adapters = adapters
        self.sdk = sdk
        self.extras = extras
        self.adRevenueObserver = adRevenueObserver
        self.buildAuction = buildAuction
    }

    func runFull(
        pricefloor: Price,
        auctionKey: String?,
        excludedDemandIds: Set<String>,
        existingTokens: [BiddingDemandToken] = [],
        startTimestamp: TimeInterval?
    ) {
        guard let configParameters = ConfigParametersStorage.adaptersInitializationParameters else {
            Logger.vManager(context.adType, "VAuctionEngine.runFull: no config parameters")
            onComplete?(nil)
            return
        }

        let existingTokenDemandIds = Set(existingTokens.map(\.demandId))
        let demands = configParameters.adapters
            .map { $0.demandId }
            .filter { !existingTokenDemandIds.contains($0) }

        let builder = DemandsTokensManagerBuilder<AdTypeContextType>()
        builder.withDemands(demands)
        builder.withAdapters(adapters)
        builder.withTimeout(ConfigParametersStorage.tokenTimeout ?? Constants.Timeout.defaultTokensTimeout)
        builder.withContext(context)
        builder.withAuctionKey(auctionKey)
        builder.withAdaptersRepository(sdk.adaptersRepository)

        let manager = DemandsTokensManager<AdTypeContextType>(builder: builder)
        demandsManager = manager

        Logger.vManager(context.adType, "VAuctionEngine.runFull: collecting tokens, excluded=\(excludedDemandIds), reusing=\(existingTokens.map(\.demandId))")

        manager.load(initializationParameters: configParameters) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case let .success(freshTokens):
                let filteredExisting = existingTokens.filter {
                    !excludedDemandIds.contains($0.demandId)
                }
                let mergedTokens = filteredExisting + freshTokens
                self.sendRequest(
                    tokens: mergedTokens,
                    pricefloor: pricefloor,
                    auctionKey: auctionKey,
                    excludedDemandIds: excludedDemandIds,
                    startTimestamp: startTimestamp
                )

            case let .failure(error):
                Logger.vManager(context.adType, "VAuctionEngine.runFull: token collection failed: \(error)")
                self.onComplete?(nil)
            }
        }
    }

    func stop() {
        auction?.finish()
    }

    private func sendRequest(
        tokens: [BiddingDemandToken],
        pricefloor: Price,
        auctionKey: String?,
        excludedDemandIds: Set<String>,
        startTimestamp: TimeInterval?
    ) {
        let request = context.auctionRequest { builder in
            builder.withBiddingTokens(tokens)
            builder.withPricefloor(pricefloor)
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withAuctionId(UUID().uuidString)
            builder.withExt(extras)
            builder.withAuctionKey(auctionKey)
        }
        Logger.vManager(context.adType, "VAuctionEngine: sending auction request")

        networkManager.perform(request: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(response):
                self.onAuctionResponse?(response)
                self.startWaterfall(
                    response: response,
                    tokens: tokens,
                    excludedDemandIds: excludedDemandIds,
                    startTimestamp: startTimestamp
                )

            case let .failure(error):
                Logger.vManager(context.adType, "VAuctionEngine: request failed: \(error)")
                self.onComplete?(nil)
            }
        }
    }

    private func startWaterfall(
        response: AuctionRequest.ResponseBody,
        tokens: [BiddingDemandToken],
        excludedDemandIds: Set<String>,
        startTimestamp: TimeInterval?
    ) {
        let configuration = AuctionConfiguration(auction: response, tokens: tokens)
        let observer = BaseAuctionObserver(configuration: configuration, adType: context.adType)

        if let startTimestamp {
            observer.log(StartAuctionEvent(startTimestamp: startTimestamp))
        }

        let provider = DefaultAdUnitProvider(adUnits: response.adUnits)
        let auction = buildAuction(provider, observer, configuration)
        self.auction = auction

        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }
            guard !excludedDemandIds.contains(bid.adUnit.demandId) else {
                Logger.vManager(context.adType, "VAuctionEngine: skip excluded \(bid.adUnit.demandId)")
                return
            }
            Logger.vManager(context.adType, "VAuctionEngine: bid \(bid.adUnit.demandId)@\(bid.price.debugString)")
            self.onBidLoaded?(bid, configuration)
        }

        auction.load { [weak self, observer] _ in
            guard let self else {
                return
            }
            Logger.vManager(context.adType, "VAuctionEngine: waterfall complete")
            self.auction = nil
            self.onComplete?(observer.report)
        }
    }
}
