//
//  DBannerAdManager.swift
//  Bidon
//
//  Created by Dzmitry on 24/02/2026.
//

final class DBannerAdManager: BannerAdManager {
    typealias AuctionControllerType = DAuctionController<BannerAdTypeContext>
    typealias BidType = AnyAdViewBid

    private let cache = DimaSandbox.cache
    private let cacheStats = DimaSandbox.cacheStats
    private let cachePolicy = DimaSandbox.Banner.cachePolicy

    override func performAuction(
        auctionInfo: AuctionInfo,
        tokens: [BiddingDemandToken],
        viewContext: AdViewContext
    ) {
        if isCanceled {
            Logger.dAuction("Cancelled")
            return
        }
        Logger.dAuction(
            "performAuction called with \(auctionInfo.adUnits.count) adUnits, \(tokens.count) tokens, pricefloor: \(auctionInfo.pricefloor)"
        )

        let configuration = AuctionConfiguration(auction: auctionInfo, tokens: tokens)
        let observer = BaseAuctionObserver(configuration: configuration, adType: .banner)

        if let auctionStartTimestamp {
            observer.log(StartAuctionEvent(startTimestamp: auctionStartTimestamp))
        }

        let auction = buildAuction(
            auctionInfo: auctionInfo,
            configuration: configuration,
            viewContext: viewContext,
            observer: observer
        )
        state = .auction(controller: auction)

        auction.load { [weak self, observer, viewContext] result in
            self?.finalizeAuctionInfo(from: observer.report, viewContext: viewContext)

            switch result {
            case let .success(bids):
                self?.handleAuctionSuccess(bids: bids, configuration: configuration, viewContext: viewContext)
            case let .failure(error):
                self?.handleAuctionFailure(error, configuration: configuration)
            }
        }
    }

    private func buildAuction(
        auctionInfo: AuctionInfo,
        configuration: AuctionConfiguration,
        viewContext: AdViewContext,
        observer: BaseAuctionObserver
    ) -> AuctionControllerType {
        let context = BannerAdTypeContext(viewContext: viewContext)
        let provider = DefaultAdUnitProvider(adUnits: auctionInfo.adUnits)

        let auction = AuctionControllerType { (builder: AdViewConcurrentAuctionControllerBuilder) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withAdUnitProvider(provider)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withContext(context)
            builder.withViewContext(viewContext)
            builder.withAuctionObserver(observer)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withAuctionConfiguration(configuration)
        }
        return auction
    }

    private func finalizeAuctionInfo(from report: any AuctionReport, viewContext: AdViewContext) {
        sendAuctionReport(report, viewContext: viewContext)

        var allDemands = report.round.demands
        if let biddingDemands = report.round.bidding?.demands {
            allDemands.append(contentsOf: biddingDemands)
        }
        auctionInfo.adUnits = allDemands.compactMap { DefaultAdUnitInfo($0) }
    }

    private func prepareReadyState(for winner: BidType, viewContext: AdViewContext) {
        let context = BannerAdTypeContext(viewContext: viewContext)
        let impression = AdViewImpression(bid: winner.unwrapped(), format: context.format)
        adRevenueObserver.observe(winner)
        state = .ready(impression: impression)
    }

    private func prepareReadyStateFromCache(entry: CachedBid) {
        let impression: AdViewImpression = entry.buildImpressionController()!
        entry.observeRevenue(adRevenueObserver)
        state = .ready(impression: impression)
    }

    private func handleAuctionSuccess(bids: [BidType], configuration: AuctionConfiguration, viewContext: AdViewContext) {
        Logger.dAuction("Completed with \(bids.count) bids")

        guard !bids.isEmpty else {
            handleAuctionFailure(.noFill, configuration: configuration)
            return
        }
        var allBids = bids
        let winner = allBids.removeFirst()

        handleWinner(winner, runnerUps: allBids, configuration: configuration, viewContext: viewContext)
    }

    private func handleAuctionFailure(_ error: SdkError, configuration: AuctionConfiguration) {
        Logger.dAuction("Completed with error \(error.description)")

        if let fallbackBid = fallbackBid(minPrice: configuration.pricefloor) {
            handleCachedBid(fallbackBid)
        } else {
            handleCacheFallbackFailed(with: error)
        }
    }

    private func handleWinner(_ winner: BidType, runnerUps: [BidType], configuration: AuctionConfiguration, viewContext: AdViewContext) {
        Logger.dPolicy("Winner: demandId=\(winner.adUnit.demandId), price=\(winner.price.debugString)")

        DispatchQueue.main.async { [self, auctionInfo] in
            let ad = AdContainer(bid: winner)
            prepareReadyState(for: winner, viewContext: viewContext)
            delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
        }
        cacheRunnerUps(runnerUps: runnerUps, configuration: configuration, viewContext: viewContext)
    }
}

private extension DBannerAdManager {
    var cacheKey: CacheKey {
        .banner()
    }

    func cacheRunnerUps(runnerUps: [BidType], configuration: AuctionConfiguration, viewContext: AdViewContext) {
        let context = BannerAdTypeContext(viewContext: viewContext)
        let newEntries = cachePolicy.selectRunnerUps(
            from: runnerUps,
            auctionID: configuration.auctionId
        ) { bid, meta in
            CachedBid(
                meta: meta,
                payload: .init(
                    adType: .banner,
                    demandID: bid.adUnit.demandId,
                    auctionID: configuration.auctionId,
                    price: bid.price
                ),
                makeAd: {
                    Logger.dDebug("Main thread: \(Thread.isMainThread)")
                    return AdContainer(bid: bid)
                },
                makeImpressionController: {
                    Logger.dDebug("Main thread: \(Thread.isMainThread)")
                    return AdViewImpression(bid: bid.unwrapped(), format: context.format) as AnyObject
                },
                observeRevenue: { observer in observer.observe(bid) }
            )
        }

        cache.maintenance()
        let cached = cache.peek(key: cacheKey).filter { !$0.isExpired }
        let entriesToCache = cachePolicy.selectRunnerUpsToCache(
            cached: cached,
            new: newEntries
        )
        cache.replace(key: cacheKey, entries: entriesToCache)
    }

    func fallbackBid(minPrice: Price) -> CachedBid? {
        Logger.dPolicy("Fallback attempted")
        cache.maintenance()

        let cached = cache.peek(key: cacheKey)
        let available = cachePolicy.selectFallbackCandidates(
            cachedSnapshot: cached,
            minPrice: minPrice
        )
        let cachedBid = available.first(
            where: { candidate in
                cache.reserve(entryID: candidate.meta.entryID) != nil
            }
        )
        return cachedBid
    }

    private func handleCachedBid(_ bid: CachedBid) {
        countFallbackSuccess(bid: bid)
        cache.confirm(entryID: bid.meta.entryID)
        DispatchQueue.main.async { [self] in
            let ad = bid.makeAd()
            prepareReadyStateFromCache(entry: bid)
            delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
        }
    }

    private func handleCacheFallbackFailed(with error: SdkError) {
        countFallbackFailure()
        DispatchQueue.main.async { [self] in
            state = .idle
            delegate?.adManager(self, didFailToLoad: error, auctionInfo: auctionInfo)
        }
    }

    private func countFallbackSuccess(bid: CachedBid) {
        Logger.dPolicy(
            "Fallback success: demandId=\(bid.payload.demandID), price=\(bid.payload.price.debugString), TTL=\(Int(bid.remainingTTL))s"
        )
        cacheStats.recordHit()
        cacheStats.recordSavedFill()
    }

    private func countFallbackFailure() {
        Logger.dPolicy("Fallback fail: no valid entries")
        cacheStats.recordMiss()
    }
}
