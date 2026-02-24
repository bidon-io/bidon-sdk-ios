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
        Logger.dAuction(
            "performAuction called with \(auctionInfo.adUnits.count) adUnits, \(tokens.count) tokens, pricefloor: \(auctionInfo.pricefloor)"
        )
        if isCanceled {
            return
        }

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

    private func prepareReadyStateFromCache(entry: CachedBid) -> Bool {
        let impression: AdViewImpression? = performSyncOnMain {
            entry.buildImpressionController()
        }
        guard let impression else {
            return false
        }
        entry.observeRevenue(adRevenueObserver)
        state = .ready(impression: impression)
        return true
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
        guard fallbackFill(minPrice: configuration.pricefloor) == false else {
            return
        }
        state = .idle
        notifyDidFailToLoad(error)
    }

    private func handleWinner(_ winner: BidType, runnerUps: [BidType], configuration: AuctionConfiguration, viewContext: AdViewContext) {
        Logger.dPolicy("Winner: demandId=\(winner.adUnit.demandId), price=\(fmt(winner.price))")
        cacheRunnerUps(runnerUps: runnerUps, configuration: configuration, viewContext: viewContext)

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            let ad = AdContainer(bid: winner)
            prepareReadyState(for: winner, viewContext: viewContext)
            notifyDidLoad(ad)
        }
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

    @discardableResult
    func fallbackFill(minPrice: Price) -> Bool {
        Logger.dPolicy("Fallback attempted")
        cache.maintenance()

        let cached = cache.peek(key: cacheKey)
        let available = cachePolicy.selectFallbackCandidates(
            cachedSnapshot: cached,
            minPrice: minPrice
        )

        for candidate in available {
            guard let entry = cache.reserve(entryID: candidate.meta.entryID) else {
                continue
            }
            guard tryToFill(with: entry) else {
                logFallbackFailure(entry)
                continue
            }
            return true
        }

        Logger.dPolicy("Fallback fail: no valid entries")
        cacheStats.recordMiss()
        return false
    }

    @discardableResult
    private func tryToFill(with cacheBid: CachedBid) -> Bool {
        let prepared = prepareReadyStateFromCache(entry: cacheBid)
        guard prepared else {
            return false
        }
        let ad = cacheBid.makeAd()
        logFallbackSuccess(cacheBid)
        notifyDidLoad(ad)
        return true
    }

    private func logFallbackFailure(_ cacheBid: CachedBid) {
        Logger.dPolicy(
            "Fallback fail: controller build fail, demandId=\(cacheBid.payload.demandID)"
        )
        cache.release(entryID: cacheBid.meta.entryID)
        cacheStats.recordInvalid()
    }

    private func logFallbackSuccess(_ cacheBid: CachedBid) {
        Logger.dPolicy(
            "Fallback success: demandId=\(cacheBid.payload.demandID), price=\(fmt(cacheBid.payload.price)), TTL=\(Int(cacheBid.remainingTTL))s"
        )
        cacheStats.recordHit()
        cacheStats.recordSavedFill()
    }
}

private extension DBannerAdManager {
    func notifyDidLoad(_ ad: Ad) {
        performAsyncOnMain {
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
        }
    }

    func notifyDidFailToLoad(_ error: SdkError) {
        performAsyncOnMain {
            self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
        }
    }

    func performAsyncOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async { block() }
        }
    }

    func performSyncOnMain<T>(_ block: @escaping () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            try block()
        } else {
            try DispatchQueue.main.sync { try block() }
        }
    }

    func fmt(_ price: Price) -> String {
        String(format: "%.2f", price)
    }
}
