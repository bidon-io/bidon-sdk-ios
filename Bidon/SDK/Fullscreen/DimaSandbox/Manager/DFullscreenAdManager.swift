//
//  DFullscreenAdManager.swift
//  Bidon
//

import Foundation
import UIKit

typealias InterstitialBaseManager = BaseFullscreenAdManager<
    InterstitialAdTypeContext,
    InterstitialConcurrentAuctionControllerBuilder,
    InterstitialImpressionController,
    InterstitialAdaptersFetcher
>

final class DFullscreenAdManager: InterstitialBaseManager {
    typealias AuctionControllerType = DAuctionController<InterstitialAdTypeContext>
    typealias CacheMode = CacheModeDecider.Decision.Mode

    struct ExploreConfig {
        let exploreRate: Double
        let minRandomExploreInterval: TimeInterval
        let minCacheDepthForExplore: Int
    }

    private let exploreConfig = ExploreConfig.default
    private let maxRunnerUpsCount = 3

    private let profileSelector = DimaSandbox.profileSelector
    private let cache = DimaSandbox.cache
    private let cacheStats = DimaSandbox.cacheStats
    private let marketStats = DimaSandbox.marketStats
    private let floorManager = DimaSandbox.floorManager
    private let networkHealth = DimaSandbox.networkHealth
    private let warmupTracker = DimaSandbox.warmupTracker
    private let refillManager = DimaSandbox.refillManager
    private let cacheModeDecider = DimaSandbox.cacheModeDecider

    private var reservedFallbackBid: CachedBid?
    private var currentWinnerDemandId: String?
    private var lastSecondPrice: Price?
    private var lastWinnerOutlier: Bool = false

    private var isRefillAuction: Bool = false
    private var pendingRefill: Bool = false

    private lazy var proxy: CacheImpressionDelegateProxy = {
        let proxy = CacheImpressionDelegateProxy(cache: cache)
        proxy.delegate = self
        proxy.onImpression = { [weak self] demandId in
            self?.handleImpression(demandId: demandId)
        }
        proxy.onHide = { [weak self] demandId in
            self?.handleHide(demandId: demandId)
        }
        proxy.onFailToPresent = { [weak self] demandId in
            self?.handleFailToPresent(demandId: demandId)
        }
        return proxy
    }()

    private var profile: TrafficProfile {
        profileSelector.profile
    }

    override func loadAd(pricefloor: Price, auctionKey: String?) {
        // If refill is running, try to serve from cache directly (don't start another auction)
        if isRefillAuction {
            Logger.adCacheD(prefix: "Cache", message: "loadAd during refill - trying cache-only")
            let adjustedPricefloor = floorManager.adjustedFloor(requested: pricefloor)
            if let cachedBid = getReservedBid(pricefloor: adjustedPricefloor) {
                cacheStats.recordHit()
                floorManager.recordFill(ecpm: cachedBid.price)
                useCachedBid(cachedBid)
            } else {
                Logger.adCacheD(prefix: "Cache", message: "No cache during refill, failing")
                notifyDidFailToLoad(.noFill)
            }
            return
        }

        let adjustedPricefloor = floorManager.adjustedFloor(requested: pricefloor)
        Logger.adCacheD(prefix: "Cache", message: "loadAd called with pricefloor: \(pricefloor) (adjusted: \(adjustedPricefloor)), profile=\(profile), state=\(state), sdkInitialized=\(BidonSdk.isInitialized)")

        floorManager.recordRequest()
        reservedFallbackBid = nil

        if shouldExplore() {
            Logger.adCacheD(prefix: "Cache", message: "Skipping cache due to EXPLORE SLOT - running full auction")
            cacheStats.recordMiss()
            super.loadAd(pricefloor: adjustedPricefloor, auctionKey: auctionKey)
            return
        }

        guard let cachedBid = getReservedBid(pricefloor: adjustedPricefloor) else {
            Logger.adCacheD(prefix: "Cache", message: "Cache MISS - calling super.loadAd()")
            cacheStats.recordMiss()
            super.loadAd(pricefloor: adjustedPricefloor, auctionKey: auctionKey)
            Logger.adCacheD(prefix: "Cache", message: "super.loadAd() returned, state=\(state)")
            return
        }

        let mode = decideCacheMode(for: cachedBid)
        Logger.adCacheD(prefix: "Cache", message: "Cache HIT - mode: \(mode), bid: \(cachedBid.demandId) @ \(cachedBid.price)")

        switch mode {
        case .useCache:
            cacheStats.recordHit()
            floorManager.recordFill(ecpm: cachedBid.price)
            useCachedBid(cachedBid)

        case .tryToBeat:
            let beatMultiplier = profile.tryToBeat.beatMultiplier
            let targetFloor = max(adjustedPricefloor, cachedBid.price * beatMultiplier)
            Logger.adCacheD(prefix: "Cache", message: "Mode B: Try to beat cached=\(fmt(cachedBid.price)), targetFloor=\(fmt(targetFloor))")
            reservedFallbackBid = cachedBid
            super.loadAd(pricefloor: targetFloor, auctionKey: auctionKey)

        case .fullAuction:
            // Use cooldown to prevent immediate re-reservation of rejected entry
            cache.releaseWithCooldown(entryId: cachedBid.meta.entryId)
            cacheStats.recordMiss()
            super.loadAd(pricefloor: adjustedPricefloor, auctionKey: auctionKey)
        }
    }

    private func useCachedBid(_ cachedBid: CachedBid) {
        let controller: InterstitialImpressionController? = cachedBid.buildImpressionController()

        guard let controller else {
            Logger.adCacheD(prefix: "Cache", message: "Failed to build impression controller from cached bid, releasing")
            cache.release(entryId: cachedBid.meta.entryId)
            cacheStats.recordMiss()
            notifyDidFailToLoad(.noFill)
            return
        }

        proxy.setCachedEntryId(cachedBid.meta.entryId)
        proxy.currentDemandId = cachedBid.demandId
        currentWinnerDemandId = cachedBid.demandId

        controller.delegate = proxy
        state = .ready(controller: controller)

        let ad = cachedBid.makeAd()
        Logger.adCacheD(prefix: "Cache", message: "Mode A: Loaded ad from cache: demandId=\(cachedBid.demandId), price=\(cachedBid.price), TTL remaining=\(cachedBid.remainingTTL)s")
        notifyDidLoad(ad)
    }

    override func performAuction(_ auctionInfo: AuctionInfo, tokens: [BiddingDemandToken]) {
        Logger.adCacheD(prefix: "Auction", message: "performAuction called with \(auctionInfo.adUnits.count) adUnits, \(tokens.count) tokens")
        let configuration = AuctionConfiguration(auction: auctionInfo, tokens: tokens)

        let observer = BaseAuctionObserver(
            configuration: configuration,
            adType: context.adType
        )
        if let auctionStartTimestamp {
            observer.log(StartAuctionEvent(startTimestamp: auctionStartTimestamp))
        }

        let provider = DefaultAdUnitProvider(adUnits: auctionInfo.adUnits)

        let auction = AuctionControllerType { (builder: InterstitialConcurrentAuctionControllerBuilder) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withAdUnitProvider(provider)
            builder.withAuctionObserver(observer)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withContext(context)
            builder.withAuctionConfiguration(configuration)
        }

        state = .auction(controller: auction)

        auction.load { [weak self, observer] result in
            self?.finalizeAuctionInfo(from: observer.report)

            switch result {
            case let .success(bids):
                self?.handleAuctionSuccess(bids: bids, configuration: configuration)
            case let .failure(error):
                self?.handleAuctionFailure(error)
            }
        }
    }

    private func finalizeAuctionInfo(from report: any AuctionReport) {
        sendAuctionReport(report)

        var allDemands = report.round.demands
        if let biddingDemands = report.round.bidding?.demands {
            allDemands.append(contentsOf: biddingDemands)
        }
        auctionInfo.adUnits = allDemands.compactMap { DefaultAdUnitInfo($0) }
    }

    private func handleAuctionSuccess(bids: [BidType], configuration: AuctionConfiguration) {
        proxy.clearCachedEntryId()
        Logger.adCacheD(prefix: "Auction", message: "Completed with \(bids.count) bids")

        if isRefillAuction {
            handleRefillSuccess(bids: bids, configuration: configuration)
            return
        }

        if tryToBeat(winner: bids.first) {
            return
        }

        guard let winner = bids.first else {
            handleNoFill()
            return
        }

        handleWinner(winner, allBids: bids, configuration: configuration)
    }

    private func handleNoFill() {
        floorManager.maybeAdjust()
        state = .idle
        notifyDidFailToLoad(.noFill)
    }

    private func handleWinner(_ winner: BidType, allBids: [BidType], configuration: AuctionConfiguration) {
        recordMarketAndHealth(winner: winner, allBids: allBids)
        cacheRunnerUps(allBids: allBids, configuration: configuration)

        _ = prepareReadyState(for: winner, secondPrice: lastSecondPrice)
        let ad = AdContainer(bid: winner)

        notifyDidLoad(ad)
    }

    private func recordMarketAndHealth(winner: BidType, allBids: [BidType]) {
        let secondPrice = allBids.dropFirst().first?.price
        lastSecondPrice = secondPrice

        let snap = marketStats.snapshot()
        let statsWarm = snap.count >= marketStats.minSamples

        let outlierResult = warmupTracker.detectOutlier(
            winner: winner.price,
            secondPrice: secondPrice,
            p80: snap.p80
        )
        lastWinnerOutlier = outlierResult.isOutlier

        let isTrusted = warmupTracker.isWinnerTrusted(
            winner: winner.price,
            secondPrice: secondPrice,
            p80: snap.p80,
            statsWarm: statsWarm
        )
        DimaSandbox.lastWinnerTrusted = isTrusted

        let dampenedPrice = warmupTracker.dampenedWinner(winner.price, p80: snap.p80)

        if outlierResult.isOutlier {
            Logger.adCacheD(prefix: "Warmup", message: "Outlier: \(outlierResult.reason ?? "unknown"), dampened=\(fmt(dampenedPrice))")
        }

        marketStats.recordWin(dampenedPrice)
        warmupTracker.recordWinner(price: dampenedPrice)
        profileSelector.recordWin(winner.price)

        floorManager.recordFill(ecpm: winner.price)
        floorManager.maybeAdjust()

        DimaSandbox.lastFullAuctionAt = Date()

        for bid in allBids {
            networkHealth.recordFill(demandId: bid.adUnit.demandId)
        }

        Logger.adCacheD(
            prefix: "Market",
            message: "winner=\(fmt(winner.price)), second=\(secondPrice.map { fmt($0) } ?? "nil"), trusted=\(isTrusted), outlier=\(lastWinnerOutlier), profile=\(profile)"
        )
    }

    private func prepareReadyState(for winner: BidType, secondPrice: Price?) -> InterstitialImpressionController {
        adRevenueObserver.observe(winner)

        let controller = InterstitialImpressionController(bid: winner)
        controller.delegate = proxy

        proxy.currentDemandId = winner.adUnit.demandId
        currentWinnerDemandId = winner.adUnit.demandId
        refillManager.recordWinnerPrice(winner.price, secondPrice: secondPrice)

        state = .ready(controller: controller)
        return controller
    }
    
    private func cacheRunnerUps(allBids: [BidType], configuration: AuctionConfiguration) {
        guard let winner = allBids.first else { return }

        let minPrice = calculateMinPriceForCaching(
            winnerPrice: winner.price,
            pricefloor: configuration.pricefloor
        )

        var seenDemandIds = Set<String>()
        var runnerUps: [CachedBid] = []
        var skippedCount = 0

        for loser in allBids.dropFirst() {
            guard loser.price >= minPrice else {
                skippedCount += 1
                continue
            }

            let demandID = loser.adUnit.demandId
            guard !seenDemandIds.contains(demandID) else { continue }
            seenDemandIds.insert(demandID)

            let cached = CachedBid(
                meta: .cached(withTTL: 220, consentHash: "v0"),
                payload: .init(
                    adType: .interstitial,
                    demandId: demandID,
                    auctionId: configuration.auctionId,
                    price: loser.price
                ),
                makeAd: { AdContainer(bid: loser) },
                makeImpressionController: { InterstitialImpressionController(bid: loser) as AnyObject }
            )

            runnerUps.append(cached)
            if runnerUps.count >= maxRunnerUpsCount { break }
        }

        guard !runnerUps.isEmpty else { return }

        let prices = runnerUps.map { fmt($0.price) }.joined(separator: ", ")
        Logger.adCacheD(prefix: "Cache", message: "Stored \(runnerUps.count) runner-ups [\(prices)], skipped=\(skippedCount), minPrice=\(fmt(minPrice))")
        cache.store(runnerUps, winnerPrice: winner.price, adType: .interstitial)
    }

    private func calculateMinPriceForCaching(winnerPrice: Price, pricefloor: Price) -> Price {
        let cacheConfig = profile.cache
        let tryToBeatConfig = profile.tryToBeat
        let snap = marketStats.snapshot()
        let cacheDepth = cache.count(adType: .interstitial)
        let isColdStart = warmupTracker.isColdStart
        let statsWarm = snap.count >= marketStats.minSamples
        let isTrusted = DimaSandbox.lastWinnerTrusted

        // Use depth buffer for QUALITY mode threshold
        let healthyDepth = refillManager.targetDepth + tryToBeatConfig.depthBuffer
        let needsDepth = isColdStart || cacheDepth < healthyDepth

        if needsDepth {
            let fillDepthFloor = max(pricefloor, floorManager.currentFloor, cacheConfig.minCachePriceFloor)
            Logger.adCacheD(prefix: "Cache", message: "FILL-DEPTH mode: minPrice=\(fmt(fillDepthFloor)) (depth=\(cacheDepth)/\(healthyDepth), cold=\(isColdStart))")
            return fillDepthFloor
        }

        var qualityFloor = pricefloor

        if let p80 = snap.p80 {
            let p80Floor = p80 * cacheConfig.p80CacheMultiplier
            qualityFloor = max(qualityFloor, p80Floor)
        }

        // WinnerShare only if trusted AND not outlier
        if !lastWinnerOutlier && isTrusted {
            let winnerFloor = winnerPrice * cacheConfig.winnerShare
            qualityFloor = max(qualityFloor, winnerFloor)
        }

        let maxFloor = winnerPrice * 0.95
        qualityFloor = min(qualityFloor, maxFloor)

        qualityFloor = max(qualityFloor, cacheConfig.minCachePriceFloor)

        Logger.adCacheD(prefix: "Cache", message: "QUALITY mode: minPrice=\(fmt(qualityFloor)) (statsWarm=\(statsWarm), outlier=\(lastWinnerOutlier), trusted=\(isTrusted))")
        return qualityFloor
    }

    private func handleAuctionFailure(_ error: SdkError) {
        if isRefillAuction {
            handleRefillFailure(error: error)
            return
        }
        if fallbackFill() {
            return
        }
        floorManager.maybeAdjust()
        state = .idle

        notifyDidFailToLoad(error)
    }
    
    @discardableResult
    private func tryToBeat(winner: BidType?) -> Bool {
        guard let fallback = reservedFallbackBid else {
            return false
        }

        // Use beatMargin from CacheModeDecider for proper "beat" check
        if let winner {
            let didBeat = cacheModeDecider.didBeatFallback(
                winnerPrice: winner.price,
                fallbackPrice: fallback.price
            )
            if didBeat {
                Logger.adCacheD(prefix: "Cache", message: "Mode B: Auction beat cache! winner=\(fmt(winner.price)) >= fallback=\(fmt(fallback.price))*(1+margin)")
                cache.release(entryId: fallback.meta.entryId)
                reservedFallbackBid = nil
                return false
            }
        }

        let reason = winner.map { "winner=\(fmt($0.price)) didn't beat fallback=\(fmt(fallback.price))" } ?? "no bids"
        Logger.adCacheD(prefix: "Cache", message: "Mode B: Using fallback (\(reason))")

        reservedFallbackBid = nil
        cacheStats.recordHit()
        useCachedBid(fallback)

        return true
    }

    @discardableResult
    private func fallbackFill() -> Bool {
        guard let fallback = reservedFallbackBid else {
            return false
        }
        reservedFallbackBid = nil

        cacheStats.recordSavedFill()
        floorManager.recordFill(ecpm: fallback.price)
        floorManager.maybeAdjust()

        useCachedBid(fallback)

        return true
    }

    private func decideCacheMode(for cachedBid: CachedBid) -> CacheMode {
        let snap = marketStats.snapshot()
        let refillStats = refillManager.stats()
        let now = Date()
        let isColdStart = warmupTracker.isColdStart
        let statsWarm = snap.count >= marketStats.minSamples
        let cacheDepth = cache.count(adType: .interstitial)

        let decision = cacheModeDecider.decide(
            for: .init(
                cachedPrice: cachedBid.price,
                remainingTTL: cachedBid.remainingTTL,
                marketP80: snap.p80,
                lastWinnerPrice: refillStats.lastWinnerPrice,
                isLastWinnerTrusted: DimaSandbox.lastWinnerTrusted,
                isLastWinnerOutlier: lastWinnerOutlier,
                now: now,
                lastPriceGapModeBAt: DimaSandbox.lastPriceGapModeBAt,
                isColdStart: isColdStart,
                isStatsWarm: statsWarm,
                cacheDepth: cacheDepth,
                targetDepth: refillManager.targetDepth
            )
        )

        if decision.markPriceGapNow {
            DimaSandbox.lastPriceGapModeBAt = now
        }
        Logger.adCacheD(prefix: "Cache", message: "Mode \(decision.mode): \(decision.reason)")

        return decision.mode
    }

    private func getReservedBid(pricefloor: Price) -> CachedBid? {
        cache.performMaintenance()

        Logger.adCacheD(prefix: "Cache", message: "Attempting to reserve bid, pricefloor: \(fmt(pricefloor))")

        let reserved = cache.reserve(
            adType: .interstitial,
            pricefloor: pricefloor
        )
        guard let reserved, reserved.isValid(currentConsentHash: "v0") else {
            Logger.adCacheD(prefix: "Cache", message: "No valid cached bid found")
            return nil
        }
        Logger.adCacheD(prefix: "Cache", message: "Reserved: demandId=\(reserved.demandId), price=\(fmt(reserved.price)), entryId=\(reserved.meta.entryId)")
        return reserved
    }

    private func shouldExplore() -> Bool {
        let random = Double.random(in: 0..<1)
        guard random < exploreConfig.exploreRate else {
            return false
        }

        if let lastAuction = DimaSandbox.lastFullAuctionAt {
            let elapsed = Date().timeIntervalSince(lastAuction)
            if elapsed < exploreConfig.minRandomExploreInterval {
                Logger.adCacheD(prefix: "Cache", message: "Explore suppressed (warmup: \(Int(elapsed))s)")
                return false
            }
        }

        let cacheDepth = cache.count(adType: .interstitial)
        if cacheDepth < exploreConfig.minCacheDepthForExplore {
            Logger.adCacheD(prefix: "Cache", message: "Explore suppressed (depth=\(cacheDepth))")
            return false
        }

        let snap = marketStats.snapshot()
        if snap.count < marketStats.minSamples {
            Logger.adCacheD(prefix: "Cache", message: "Explore suppressed (stats cold)")
            return false
        }

        Logger.adCacheD(prefix: "Cache", message: "EXPLORE SLOT triggered")
        return true
    }

    private func handleImpression(demandId: String?) {
        guard let demandId else { return }

        networkHealth.recordShow(demandId: demandId)
        warmupTracker.recordImpression()

        let cacheDepth = cache.count(adType: .interstitial)
        let refillStats = refillManager.stats()

        Logger.adCacheD(
            prefix: "Refill",
            message: "Impression: demandId=\(demandId), depth=\(cacheDepth), refills=\(refillStats.refillsThisSession), cold=\(warmupTracker.isColdStart)"
        )

        let decision = refillManager.shouldRefill(
            cacheDepth: cacheDepth,
            reason: .postImpression
        )

        Logger.adCacheD(prefix: "Refill", message: "Decision: shouldRefill=\(decision.shouldRefill), reason=\(decision.reason)")

        if decision.shouldRefill {
            pendingRefill = true
            Logger.adCacheD(prefix: "Refill", message: "Refill pending (will execute on hide)")
        }
    }

    private func handleHide(demandId: String?) {
        currentWinnerDemandId = nil
        Logger.adCacheD(prefix: "Refill", message: "Ad hidden")

        if pendingRefill {
            pendingRefill = false
            Logger.adCacheD(prefix: "Refill", message: "Executing pending refill")
            scheduleRefillAuction()
        }
    }

    private func handleFailToPresent(demandId: String?) {
        guard let demandId else { return }
        networkHealth.recordFailToPresent(demandId: demandId)
    }
    
    private func notifyDidLoad(_ ad: Ad) {
        performAsyncOnMain {
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
        }
    }

    private func notifyDidFailToLoad(_ error: SdkError) {
        performAsyncOnMain {
            self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
        }
    }

    private func performAsyncOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async { block() }
        }
    }

    private func fmt(_ price: Price) -> String {
        String(format: "%.2f", price)
    }
}

private extension DFullscreenAdManager {
    func scheduleRefillAuction() {
        guard !isRefillAuction else {
            Logger.adCacheD(prefix: "Refill", message: "Already running refill auction, skipping")
            return
        }

        isRefillAuction = true

        let snap = marketStats.snapshot()
        let refillStats = refillManager.stats()
        let cacheDepth = cache.count(adType: .interstitial)

        let context = RefillManager.RefillContext(
            p80: snap.p80,
            secondPrice: refillStats.lastSecondPrice,
            stickyFloor: floorManager.currentFloor,
            isColdStart: warmupTracker.isColdStart,
            isOutlier: lastWinnerOutlier,
            cacheDepth: cacheDepth
        )

        let (floor, source) = refillManager.calculateRefillFloor(context: context)
        Logger.adCacheD(prefix: "Refill", message: "Starting refill auction: floor=\(fmt(floor)), source=\(source.rawValue)")

        super.loadAd(pricefloor: floor, auctionKey: nil)
    }

    func handleRefillSuccess(bids: [BidType], configuration: AuctionConfiguration) {
        Logger.adCacheD(prefix: "Refill", message: "Succeeded with \(bids.count) bids (silent)")

        refillManager.recordRefill()

        for bid in bids {
            networkHealth.recordFill(demandId: bid.adUnit.demandId)
        }

        cacheRunnerUps(allBids: bids, configuration: configuration)
        resetRefillState()
    }

    func handleRefillFailure(error: SdkError) {
        Logger.adCacheD(prefix: "Refill", message: "Failed: \(error) (silent)")
        refillManager.recordRefillFailure()
        resetRefillState()
    }

    func resetRefillState() {
        guard isRefillAuction else {
            Logger.adCacheD(prefix: "Refill", message: "resetRefillState: not in refill mode")
            return
        }
        state = .idle
        isRefillAuction = false
    }
}
