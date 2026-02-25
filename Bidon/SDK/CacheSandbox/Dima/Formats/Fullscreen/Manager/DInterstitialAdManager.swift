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
    private let cachePolicy = DimaSandbox.Interstitial.cachePolicy

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
    
    private func prepareReadyStateFromCache(entry: CachedBid) {
        let controller: InterstitialImpressionController = entry.buildImpressionController()!
        
        entry.observeRevenue(adRevenueObserver)
        impressionProxy.setCachedEntryId(entry.meta.entryID)
        prepareReady(demandID: entry.payload.demandID, controller: controller)
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
    
        if let fallbackBid = fallbackBid(minPrice: configuration.pricefloor) {
            handleCachedBid(fallbackBid)
        } else {
            handleCacheFallbackFailed(with: error)
        }
    }

    private func handleWinner(_ winner: BidType, runnerUps: [BidType], configuration: AuctionConfiguration) {
        Logger.dPolicy("Winner: demandId=\(winner.adUnit.demandId), price=\(winner.price.debugString)")
        
        DispatchQueue.main.async { [self, auctionInfo] in
            let ad = AdContainer(bid: winner)
            prepareReadyState(for: winner)
            
            delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
        }
        cacheRunnerUps(runnerUps: runnerUps, configuration: configuration)
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
                    return AdContainer(bid: bid)
                },
                makeImpressionController: {
                    return InterstitialImpressionController(bid: bid)
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
