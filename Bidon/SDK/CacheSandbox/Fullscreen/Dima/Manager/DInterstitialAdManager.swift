//
//  DInterstitialAdManager.swift
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

final class DInterstitialAdManager: InterstitialBaseManager {
    typealias AuctionControllerType = DAuctionController<InterstitialAdTypeContext>

    private let cache = DimaSandbox.cache
    private let cacheStats = DimaSandbox.cacheStats
    private let cachePolicy = DimaSandbox.cachePolicy

    private lazy var impressionProxy: CacheImpressionDelegateProxy = {
        let proxy = CacheImpressionDelegateProxy(cache: cache)
        proxy.delegate = self

        proxy.onImpression = { demandID in
            Logger.dProxy("Impression demandId=\(demandID ?? "nil")")
        }
        proxy.onHide = { demandID in
            Logger.dProxy("Hide demandId=\(demandID ?? "nil")")
        }
        proxy.onFailToPresent = { demandID in
            Logger.dProxy("Fail to present demandId=\(demandID ?? "nil")")
        }
        return proxy
    }()
 
    override func performAuction(
        _ auctionInfo: AuctionInfo,
        tokens: [BiddingDemandToken]
    ) {
        Logger.dAuction(
            "performAuction called with \(auctionInfo.adUnits.count) adUnits, \(tokens.count) tokens, pricefloor: \(auctionInfo.pricefloor)"
        )
      
        let configuration = AuctionConfiguration(auction: auctionInfo, tokens: tokens)

        let observer = BaseAuctionObserver(
            configuration: configuration,
            adType: context.adType
        )
        if let auctionStartTimestamp {
            let event = StartAuctionEvent(
                startTimestamp: auctionStartTimestamp
            )
            observer.log(event)
        }
        let auction = buildAuction(
            auctionInfo: auctionInfo,
            configuration: configuration,
            observer: observer
        )
        state = .auction(controller: auction)

        auction.load { [weak self, observer] result in
            self?.finalizeAuctionInfo(from: observer.report)

            switch result {
            case let .success(bids):
                self?.handleAuctionSuccess(bids: bids, configuration: configuration)
            case let .failure(error):
                self?.handleAuctionFailure(error, configuration: configuration)
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

    private func prepareReadyState(for winner: BidType) {
        let controller = InterstitialImpressionController(bid: winner)
        
        adRevenueObserver.observe(winner)
        impressionProxy.clearCachedEntryId()
        prepareReady(demandID: winner.adUnit.demandId, controller: controller)
    }
    
    private func prepareReadyStateFromCache(entry: CachedBid) -> Bool {
        let controller: InterstitialImpressionController? = performSyncOnMain {
            entry.buildImpressionController()
        }
        guard let controller else {
            return false
        }
        entry.observeRevenue(adRevenueObserver)
        impressionProxy.setCachedEntryId(entry.meta.entryID)
        prepareReady(demandID: entry.payload.demandID, controller: controller)
        
        return true
    }
    
    private func prepareReady(demandID: String, controller: InterstitialImpressionController) {
        impressionProxy.currentDemandID = demandID
        controller.delegate = impressionProxy
        
        state = .ready(controller: controller)
    }

    private func handleAuctionSuccess(bids: [BidType], configuration: AuctionConfiguration) {
        Logger.dAuction("Completed with \(bids.count) bids")

        guard !bids.isEmpty else {
            handleAuctionFailure(.noFill, configuration: configuration)
            return
        }
        var allBids = bids
        let winner = allBids.removeFirst()

        handleWinner(winner, runnerUps: allBids, configuration: configuration)
    }

    private func handleAuctionFailure(_ error: SdkError, configuration: AuctionConfiguration) {
        Logger.dAuction("Completed with error \(error.description)")
        guard fallbackFill(minPrice: configuration.pricefloor) == false else {
            return
        }
        state = .idle
        notifyDidFailToLoad(error)
    }

    private func handleWinner(_ winner: BidType, runnerUps: [BidType], configuration: AuctionConfiguration) {
        Logger.dPolicy("Winner: demandId=\(winner.adUnit.demandId), price=\(fmt(winner.price))")
        cacheRunnerUps(runnerUps: runnerUps, configuration: configuration)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            let ad = AdContainer(bid: winner)
            prepareReadyState(for: winner)
            notifyDidLoad(ad)
        }
    }

    private func buildAuction(
        auctionInfo: AuctionInfo,
        configuration: AuctionConfiguration,
        observer: BaseAuctionObserver
    ) -> AuctionControllerType {
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
        return auction
    }
}

private extension DInterstitialAdManager {
    var cacheKey: CacheKey {
        .interstitial()
    }

    func cacheRunnerUps(runnerUps: [BidType], configuration: AuctionConfiguration) {
        let newEntries = cachePolicy.selectRunnerUps(
            from: runnerUps,
            auctionID: configuration.auctionId
        ) { bid, meta in
            CachedBid(
                meta: meta,
                payload: .init(
                    adType: .interstitial,
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
                    return InterstitialImpressionController(bid: bid) as AnyObject
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

private extension DInterstitialAdManager {
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
