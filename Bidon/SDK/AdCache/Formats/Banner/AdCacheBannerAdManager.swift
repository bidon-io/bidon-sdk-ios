//
//  AdCacheBannerAdManager.swift
//  Bidon
//

import Foundation

final class AdCacheBannerAdManager: BannerAdManager {
    typealias AdCacheAuctionControllerType = AdCacheAuctionController<BannerAdTypeContext>

    private static var managers: [String: AdCacheBannerAdManager] = [:]

    static func getOrCreate(
        placement: String,
        auctionKey: String?,
        adRevenueObserver: AdRevenueObserver
    ) -> AdCacheBannerAdManager {
        let key = auctionKey ?? "default"
        if let manager = managers[key] {
            return manager
        }
        let manager = AdCacheBannerAdManager(
            placement: placement,
            adRevenueObserver: adRevenueObserver
        )
        manager.cacheKey = key
        managers[key] = manager
        return manager
    }

    var isFirstFill: Bool = true
    var auction: AdCacheAuctionControllerType?
    var cacheKey: String = "default"

    lazy var storage = Cacher.storage(for: .banner, auctionKey: cacheKey)

    // MARK: - prepareForReuse (Banner show cycle)

    override func prepareForReuse() {
        auction?.cancel()
        auction = nil
        defer { super.prepareForReuse() }
        storage.popFirst()
    }

    // MARK: - loadAd (spec §7)

    override func loadAd(pricefloor: Price, viewContext: AdViewContext, auctionKey: String?) {
        // 1. Main has ad → instant serve (no pricefloor check per spec §5)
        if let ad = storage.peekMain() as? BidContainer {
            Logger.debug("[AdCache][\(cacheKey)] [Banner] loadAd | served from cache")
            auctionInfo = DefaultAuctionInfo()
            (auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)

            let controller = AdViewImpression(
                bid: (ad.bid as! BidModel<DemandProviderWrapper<any AdViewDemandProvider>>).unwrapped(),
                format: BannerAdTypeContext(viewContext: viewContext).format
            )
            self.state = .ready(impression: controller)
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
            return
        }

        // 2. Main empty → auction
        Logger.debug("[AdCache][\(cacheKey)] [Banner] loadAd | floor: \(pricefloor) | main empty → auction")
        auctionInfo = DefaultAuctionInfo()
        super.loadAd(pricefloor: pricefloor, viewContext: viewContext, auctionKey: auctionKey)
    }

    // MARK: - Fallback on request failure (spec §7 step 3)

    override func handlePerformAuctionRequestFailed(error: any Error, viewContext: AdViewContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let ad = self.storage.peekFallback() as? BidContainer {
                Logger.debug("[AdCache][\(self.cacheKey)] [Banner] Request failed → served from fallback")
                self.auctionInfo = DefaultAuctionInfo()
                (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)
                let controller = AdViewImpression(
                    bid: (ad.bid as! BidModel<DemandProviderWrapper<any AdViewDemandProvider>>).unwrapped(),
                    format: viewContext.format
                )
                self.state = .ready(impression: controller)
                self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
            } else {
                self.sendErrorToSuperclass(error: error, viewContext: viewContext)
            }
        }
    }

    func sendErrorToSuperclass(error: Error, viewContext: AdViewContext) {
        super.handlePerformAuctionRequestFailed(error: error, viewContext: viewContext)
    }

    // MARK: - performAuction (spec §7 step 4)

    override func performAuction(
        auctionInfo: AuctionInfo,
        tokens: [BiddingDemandToken],
        viewContext: AdViewContext
    ) {
        if isCanceled { return }

        isFirstFill = true

        let configuration = AuctionConfiguration(auction: auctionInfo, tokens: tokens)

        let observer = BaseAuctionObserver(
            configuration: configuration,
            adType: .banner
        )
        if let auctionStartTimestamp {
            observer.log(StartAuctionEvent(startTimestamp: auctionStartTimestamp))
        }

        let context = BannerAdTypeContext(viewContext: viewContext)
        let provider = DefaultAdUnitProvider(adUnits: auctionInfo.adUnits)

        let auction = AdCacheAuctionControllerType { (builder: AdViewConcurrentAuctionControllerBuilder) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withAdUnitProvider(provider)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withContext(context)
            builder.withViewContext(viewContext)
            builder.withAuctionObserver(observer)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withAuctionConfiguration(configuration)
        }

        state = .auction(controller: auction)

        // Pre-filter (spec §11)
        auction.shouldCancelBeforeNextAdUnit = { [weak self] ecpm in
            self?.storage.shouldStop(ecpm: ecpm) ?? true
        }

        // Route each filled bid (spec §7 pseudocode)
        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }

            let ad = BidContainer(bid: bid)
            let result = self.storage.route(ad, sticky: self.isFirstFill)

            if result != .rejected {
                if self.isFirstFill {
                    observer.log(WinBidAuctionEvent(bid: bid))
                } else {
                    observer.log(CachedBidAuctionEvent(bid: bid))
                }
            }

            if result == .insertedMain {
                self.adRevenueObserver.observe(bid)
            }

            if self.isFirstFill && result != .rejected {
                self.adRevenueObserver.observe(bid)
                let controller = AdViewImpression(
                    bid: bid.unwrapped(),
                    format: context.format
                )
                self.state = .ready(impression: controller)

                (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                }
            }

            self.isFirstFill = false
        }

        // Auction completion (spec §10: adUnits перезаписываются)
        auction.load { [unowned observer, weak self] result in
            guard let self else { return }

            self.sendAuctionReport(observer.report, viewContext: viewContext)

            var allDemands = observer.report.round.demands
            if let biddingDemands = observer.report.round.bidding?.demands {
                allDemands += biddingDemands
            }
            self.auctionInfo.adUnits = allDemands.compactMap({ DefaultAdUnitInfo($0) })

            switch result {
            case .success:
                Logger.debug("[AdCache][\(self.cacheKey)] [Banner] Auction finished | success")

            case .failure(let error):
                Logger.debug("[AdCache][\(self.cacheKey)] [Banner] Auction finished | failure: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let ad = self.storage.peekFallback() as? BidContainer {
                        Logger.debug("[AdCache][\(self.cacheKey)] [Banner] No-fill → served from fallback")
                        (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)
                        let controller = AdViewImpression(
                            bid: (ad.bid as! BidModel<DemandProviderWrapper<any AdViewDemandProvider>>).unwrapped(),
                            format: context.format
                        )
                        self.state = .ready(impression: controller)
                        self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                    } else {
                        self.state = .idle
                        self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                    }
                }
            }

            self.auction = nil
        }

        self.auction = auction
    }
}
