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
    
    struct Configurations {
        let runnersUp: RunnerUPsConfig
        let explore: ExploreConfig
        let tryToBeat: TryToBeatConfig
    }

    struct RunnerUPsConfig {
        let count: Int
        let winnerShare: Double
    }
    
    struct ExploreConfig {
        let exploreRate: Double
        let minRandomExploreInterval: TimeInterval
        let minCacheDepthForExplore: Int
    }
    
    struct TryToBeatConfig {
        struct Threshold {
            let p80Multiplier: Double
            let lastWinnerMultiplier: Double
        }

        let beatMultiplier: Double
        let expiringTTLThreshold: TimeInterval

        let soft: Threshold
        let hard: Threshold

        let priceGapCooldown: TimeInterval
        let hardAbsoluteFloor: Price
    }
    
    private let config = Configurations(
        runnersUp: .default,
        explore: .default,
        tryToBeat: .default
    )
    
    private let cache = DimaSandbox.cache
    private let cacheStats = DimaSandbox.cacheStats
    private let marketStats = DimaSandbox.marketStats
    private let floorManager = DimaSandbox.floorManager
    private let networkHealth = DimaSandbox.networkHealth
    private let refillManager = DimaSandbox.refillManager
    private let cacheModeDecider = CacheModeDecider()

    private var reservedFallbackBid: CachedBid?
    private var currentWinnerDemandId: String?

    private var isRefillAuction: Bool = false

    private var pendingRefill: Bool = false
    private var pendingRefillFloor: Price?
    
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

    override func loadAd(pricefloor: Price, auctionKey: String?) {
        // Apply sticky floor adjustment
        let adjustedPricefloor = floorManager.adjustedFloor(requested: pricefloor)
        Logger.adCacheD(prefix: "Cache", message: "loadAd called with pricefloor: \(pricefloor) (adjusted: \(adjustedPricefloor))")

        floorManager.recordRequest()
        reservedFallbackBid = nil

        // Epsilon-greedy: 5-10% of the time, skip cache to discover price spikes
        if shouldExplore() {
            Logger.adCacheD(prefix: "Cache", message: "Skipping cache due to EXPLORE SLOT - running full auction")
            cacheStats.recordMiss()
            super.loadAd(pricefloor: adjustedPricefloor, auctionKey: auctionKey)
            return
        }

        guard let cachedBid = getReservedBid(pricefloor: adjustedPricefloor) else {
            Logger.adCacheD(prefix: "Cache", message: "Cache MISS - starting auction")
            cacheStats.recordMiss()
            super.loadAd(pricefloor: adjustedPricefloor, auctionKey: auctionKey)
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
            // Raise floor to actually beat the cached bid
            let targetFloor = max(adjustedPricefloor, cachedBid.price * config.tryToBeat.beatMultiplier)
            Logger.adCacheD(prefix: "Cache", message: "Mode B: Try to beat cached=\(String(format: "%.2f", cachedBid.price)), targetFloor=\(String(format: "%.2f", targetFloor))")
            reservedFallbackBid = cachedBid
            super.loadAd(pricefloor: targetFloor, auctionKey: auctionKey)

        case .fullAuction:
            cache.release(entryId: cachedBid.meta.entryId)
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

            performAsyncOnMain {
                self.delegate?.adManager(self, didFailToLoad: .noFill, auctionInfo: self.auctionInfo)
            }
            return
        }
        proxy.setCachedEntryId(cachedBid.meta.entryId)
        proxy.currentDemandId = cachedBid.demandId
        currentWinnerDemandId = cachedBid.demandId

        controller.delegate = proxy
        state = .ready(controller: controller)

        let ad = cachedBid.makeAd()
        Logger.adCacheD(prefix: "Cache", message: "Mode A: Loaded ad from cache: demandId=\(cachedBid.demandId), price=\(cachedBid.price), TTL remaining=\(cachedBid.remainingTTL)s")
        performAsyncOnMain {
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
        }
    }
    
    override func performAuction(_ auctionInfo: AuctionInfo, tokens: [BiddingDemandToken]) {
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
        
        auction.load { [unowned observer, weak self] result in
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

        let controller = prepareReadyState(for: winner)
        let ad = AdContainer(bid: winner)

        notifyDidLoad(ad)
    }

    private func recordMarketAndHealth(winner: BidType, allBids: [BidType]) {
        marketStats.recordWin(winner.price)
        floorManager.recordFill(ecpm: winner.price)
        floorManager.maybeAdjust()

        DimaSandbox.lastFullAuctionAt = Date()

        for bid in allBids {
            networkHealth.recordFill(demandId: bid.adUnit.demandId)
        }
    }

    private func prepareReadyState(for winner: BidType) -> InterstitialImpressionController {
        adRevenueObserver.observe(winner)

        let controller = InterstitialImpressionController(bid: winner)
        controller.delegate = proxy

        proxy.currentDemandId = winner.adUnit.demandId
        currentWinnerDemandId = winner.adUnit.demandId
        refillManager.recordWinnerPrice(winner.price)

        state = .ready(controller: controller)
        return controller
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
    
    private func cacheRunnerUps(allBids: [BidType], configuration: AuctionConfiguration) {
        guard let winner = allBids.first else { return }

        let minPrice = calculateMinPriceForCaching(winner: winner, pricefloor: configuration.pricefloor)

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
            if runnerUps.count >= config.runnersUp.count { break }
        }

        guard !runnerUps.isEmpty else {
            return
        }
        let prices = runnerUps.map { String(format: "%.2f", $0.price) }.joined(separator: ", ")
        Logger.adCacheD(prefix: "Cache", message: "Stored \(runnerUps.count) runner-ups [\(prices)], skipped=\(skippedCount), minPrice=\(String(format: "%.2f", minPrice))")
        cache.store(runnerUps, winnerPrice: winner.price, adType: .interstitial)
    }

    private func calculateMinPriceForCaching(winner: BidType, pricefloor: Price) -> Price {
        let snap = marketStats.snapshot()

        let winnerFloor = winner.price * config.runnersUp.winnerShare
        let marketFloor = snap.p80.map { $0 * config.tryToBeat.soft.p80Multiplier } ?? winnerFloor
        let statsWarm = snap.count >= marketStats.minSamples

        let combinedFloor = statsWarm
            ? max(winnerFloor, marketFloor)
            : min(winnerFloor, marketFloor)

        return min(max(pricefloor, combinedFloor), winner.price * 0.95)
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
        if let winner, winner.price >= fallback.price {
            Logger.adCacheD(prefix: "Cache", message: "Mode B: Auction beat cache! winner=\(winner.price) >= fallback=\(fallback.price)")
            cache.release(entryId: fallback.meta.entryId)
            reservedFallbackBid = nil
            
            return false
        } else {
            let reason = winner.map { "winner=\($0.price) < fallback=\(fallback.price)" } ?? "no bids"
            Logger.adCacheD(prefix: "Cache", message: "Mode B: Auction didn't beat cache (\(reason)), using fallback")

            reservedFallbackBid = nil
            cacheStats.recordHit()
            useCachedBid(fallback)
            
            return true
        }
    }
    
    @discardableResult
    private func fallbackFill() -> Bool {
        guard let fallback = self.reservedFallbackBid else {
            return false
        }
        reservedFallbackBid = nil

        cacheStats.recordSavedFill()
        floorManager.recordFill(ecpm: fallback.price)
        floorManager.maybeAdjust()

        useCachedBid(fallback)

        return true
    }
    
    private func performAsyncOnMain(_ block: @escaping () -> Void) {
        guard Thread.isMainThread == false else {
            block()
            return
        }
        DispatchQueue.main.async {
            block()
        }
    }
    
    private func shouldExplore() -> Bool {
        let random = Double.random(in: 0..<1)
        let passedRandom = random < config.explore.exploreRate

        guard passedRandom else {
            return false
        }

        if let lastAuction = DimaSandbox.lastFullAuctionAt {
            let elapsed = Date().timeIntervalSince(lastAuction)
            if elapsed < config.explore.minRandomExploreInterval {
                Logger.adCacheD(prefix: "Cache", message: "Random explore suppressed (warmup: \(Int(elapsed))s < \(Int(config.explore.minRandomExploreInterval))s)")
                return false
            }
        }

        let cacheDepth = cache.count(adType: .interstitial)
        if cacheDepth < config.explore.minCacheDepthForExplore {
            Logger.adCacheD(prefix: "Cache", message: "Random explore suppressed (cacheDepth=\(cacheDepth) < min=\(config.explore.minCacheDepthForExplore))")
            return false
        }

        let snap = marketStats.snapshot()
        if snap.count < marketStats.minSamples {
            Logger.adCacheD(prefix: "Cache", message: "Random explore suppressed (stats cold: \(snap.count) < \(marketStats.minSamples))")
            return false
        }

        Logger.adCacheD(prefix: "Cache", message: "EXPLORE SLOT triggered (random=\(String(format: "%.2f", random)), cacheDepth=\(cacheDepth), statsSamples=\(snap.count))")
        return true
    }

    private func decideCacheMode(for cachedBid: CachedBid) -> CacheMode {
        let snap = marketStats.snapshot()
        let refillStats = refillManager.stats()
        let now = Date()

        let decision = cacheModeDecider.decide(
            for: .init(
                cachedPrice: cachedBid.price,
                remainingTTL: cachedBid.remainingTTL,
                marketP80: snap.p80,
                lastWinnerPrice: refillStats.lastWinnerPrice,
                now: now,
                lastPriceGapModeBAt: DimaSandbox.lastPriceGapModeBAt,
                config: .init(beatConfig: config.tryToBeat)
            )
        )

        if decision.markPriceGapNow {
            DimaSandbox.lastPriceGapModeBAt = now
        }
        Logger.adCacheD(prefix: "Cache", message: "Using Mode \(decision.mode): \(decision.reason)")
        
        return decision.mode
    }

    private func getReservedBid(pricefloor: Price) -> CachedBid? {
        cache.performMaintenance()

        Logger.adCacheD(prefix: "Cache", message: "Attempting to reserve bid for interstitial, pricefloor: \(pricefloor)")

        let reserved = cache.reserve(
            adType: .interstitial,
            pricefloor: pricefloor
        )
        guard let reserved, reserved.isValid(currentConsentHash: "v0") else {
            Logger.adCacheD(prefix: "Cache", message: "No valid cached bid found for pricefloor: \(pricefloor)")
            return nil
        }
        Logger.adCacheD(prefix: "Cache", message: "Reserved cached bid: demandId=\(reserved.demandId), price=\(reserved.price), entryId=\(reserved.meta.entryId)")
        return reserved
    }

    private func handleImpression(demandId: String?) {
        guard let demandId else {
            return
        }
        networkHealth.recordShow(demandId: demandId)

        let cacheDepth = cache.count(adType: .interstitial)
        let refillStats = refillManager.stats()

        Logger.adCacheD(prefix: "Refill", message: "Impression: demandId=\(demandId), cacheDepth=\(cacheDepth), targetDepth=\(refillManager.targetDepth), refillsThisSession=\(refillStats.refillsThisSession), isRefillActive=\(isRefillAuction)")

        let decision = refillManager.shouldRefill(
            cacheDepth: cacheDepth,
            reason: .postImpression
        )

        Logger.adCacheD(prefix: "Refill", message: "Decision: shouldRefill=\(decision.shouldRefill), reason=\(decision.reason), suggestedFloor=\(decision.suggestedPricefloor ?? -1)")

        if decision.shouldRefill {
            pendingRefill = true
            pendingRefillFloor = decision.suggestedPricefloor
            Logger.adCacheD(prefix: "Refill", message: "Refill pending (will execute on hide)")
        }
    }

    private func handleHide(demandId: String?) {
        currentWinnerDemandId = nil
        Logger.adCacheD(prefix: "Refill", message: "Ad hidden, demandId=\(demandId ?? "nil")")

        if pendingRefill {
            pendingRefill = false
            let floor = pendingRefillFloor
            pendingRefillFloor = nil

            Logger.adCacheD(prefix: "Refill", message: "Executing pending refill (manager now idle)")
            scheduleRefillAuction(suggestedPricefloor: floor)
        }
    }

    private func handleFailToPresent(demandId: String?) {
        guard let demandId else {
            return
        }
        networkHealth.recordFailToPresent(demandId: demandId)
    }
}

private extension DFullscreenAdManager {
    private func scheduleRefillAuction(suggestedPricefloor: Price?) {
        guard !isRefillAuction else {
            Logger.adCacheD(prefix: "Refill", message: "Already running a refill auction, skipping")
            return
        }

        isRefillAuction = true

        let pricefloor = suggestedPricefloor ?? 0.1
        Logger.adCacheD(prefix: "Refill", message: "Starting refill auction with pricefloor=\(pricefloor)")

        super.loadAd(pricefloor: pricefloor, auctionKey: nil)
    }

    private func handleRefillSuccess(bids: [BidType], configuration: AuctionConfiguration) {
        Logger.adCacheD(prefix: "Refill", message: "Succeeded with \(bids.count) bids (silent)")

        refillManager.recordRefill()

        for bid in bids {
            networkHealth.recordFill(demandId: bid.adUnit.demandId)
        }

        cacheRunnerUps(allBids: bids, configuration: configuration)
        resetRefillState()
    }

    private func handleRefillFailure(error: SdkError) {
        Logger.adCacheD(prefix: "Refill", message: "Failed: \(error) (silent)")
        resetRefillState()
    }

    private func resetRefillState() {
        guard isRefillAuction else {
            Logger.adCacheD(prefix: "Refill", message: "resetRefillState called but not in refill mode, skipping state reset")
            return
        }
        state = .idle
        isRefillAuction = false
    }
}
