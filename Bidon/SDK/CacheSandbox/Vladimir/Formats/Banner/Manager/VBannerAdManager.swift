//
//  VBannerAdManager.swift
//  Bidon
//

import Foundation

final class VBannerAdManager: BannerAdManager {
    typealias BidType = AnyAdViewBid

    private let slots: VSlotManager
    private let tokenStore = VladimirSandbox.rtbTokenStore

    private enum LoadingState {
        case idle
        case loading
    }

    private let retry = AuctionRetryStrategy(adType: .banner)

    private var loadingState: LoadingState = .idle
    private var lastPricefloor: Price = .zero
    private var lastAuctionKey: String?
    private var lastViewContext: AdViewContext?

    private var engine: VAuctionEngine<BannerAdTypeContext>?

    override init(placement: String, adRevenueObserver: AdRevenueObserver) {
        slots = VSlotManager(
            store: VladimirSandbox.cache,
            key: .banner(placementId: placement)
        )
        super.init(placement: placement, adRevenueObserver: adRevenueObserver)
        slots.onVacancy = { [weak self] in
            self?.onSlotVacancy()
        }
        Logger.vManagerBanner("init: slots=\(slots.description)")
    }

    override func loadAd(pricefloor: Price, viewContext: AdViewContext, auctionKey: String?) {
        auctionInfo = DefaultAuctionInfo()
        slots.runMaintenance()
        lastPricefloor = pricefloor
        lastAuctionKey = auctionKey
        lastViewContext = viewContext

        if let slot1 = slots.slot1, slot1.payload.price >= pricefloor, let popped = slots.pop() {
            Logger.vManagerBanner("loadAd: immediate hit \(popped.payload.demandID)@\(popped.payload.price.debugString)")
            deliverCachedBid(popped, viewContext: viewContext)
            refillSlotsIfNeeded()
            return
        }

        if slots.isFull, let primaryPrice = slots.primaryPrice, primaryPrice < pricefloor {
            slots.evictBackup()
            Logger.vManagerBanner("loadAd: smart eviction (slot1 below floor)")
        }

        guard !slots.isFull else {
            Logger.vManagerBanner("loadAd: slots full, skip load")
            return
        }

        guard loadingState == .idle else {
            Logger.vManagerBanner("loadAd: already loading, skip")
            return
        }

        cancelAutoRestart()
        startLoad(pricefloor: pricefloor, viewContext: viewContext, auctionKey: auctionKey, isBackground: false)
    }

    private func startLoad(pricefloor: Price, viewContext: AdViewContext, auctionKey: String?, isBackground: Bool) {
        loadingState = .loading

        Logger.vManagerBanner("startLoad: pricefloor=\(pricefloor.debugString), isBackground=\(isBackground)")

        var callbackFired = false
        let auctionEngine = makeEngine(viewContext: viewContext)
        engine = auctionEngine

        auctionEngine.onAuctionResponse = { [weak self] response in
            guard let self, !isBackground else {
                return
            }
            auctionInfo.auctionId = response.auctionId
            auctionInfo.auctionConfigurationId = NSNumber(value: response.auctionConfigurationId)
            auctionInfo.auctionConfigurationUid = response.auctionConfigurationUid
            auctionInfo.noBids = response.noBids?.compactMap { DefaultAdUnitInfo($0) }
            auctionInfo.timeout = NSNumber(value: response.auctionTimeout)
            sdk.updateSegmentIfNeeded(response.segment)
        }

        auctionEngine.onBidLoaded = { [weak self] (bid: BidType, configuration: AuctionConfiguration) in
            guard let self else {
                return
            }
            let entry = makeCachedBid(bid, configuration: configuration, viewContext: viewContext)
            let primaryFilled = slots.insert(entry)
            retry.reset()

            Logger.vManagerBanner("onBidLoaded: \(bid.adUnit.demandId)@\(bid.price.debugString), primaryFilled=\(primaryFilled), isBackground=\(isBackground), slots=\(slots.description)")

            if !isBackground && primaryFilled && !callbackFired {
                guard let popped = slots.pop() else {
                    return
                }
                callbackFired = true
                deliverCachedBid(popped, viewContext: viewContext)
            } else if !primaryFilled {
                Logger.vManagerBanner("onBidLoaded: slot2 filled silently")
            }
            if slots.isFull {
                auctionEngine.stop()
            }
        }

        auctionEngine.onComplete = { [weak self] report in
            self?.handleAuction(report: report, isBackground: isBackground, callbackFired: callbackFired, viewContext: viewContext)
        }

        BidonSdk.addInitializationHandler { [weak self, auctionEngine] in
            guard let self else {
                return
            }
            guard BidonSdk.isInitialized else {
                Logger.warning("VBannerAdManager: SDK not initialized")
                self.loadingState = .idle
                if !isBackground {
                    self.delegate?.adManager(self, didFailToLoad: .message("SDK is not initialized"), auctionInfo: self.auctionInfo)
                }
                return
            }
            let startTimestamp: TimeInterval? = isBackground ? nil : Date.timestamp(.wall, units: .milliseconds)
            let cachedRTBTokens = self.tokenStore.consumeTokens(adType: .banner)

            self.auctionStartTimestamp = startTimestamp
            self.auctionInfo.auctionPricefloor = NSNumber(value: pricefloor)
            auctionEngine.runFull(
                pricefloor: pricefloor,
                auctionKey: auctionKey,
                excludedDemandIds: self.slots.cachedDemandIds,
                existingTokens: cachedRTBTokens,
                startTimestamp: startTimestamp
            )
        }
    }

    private func handleAuction(report: (any AuctionReport)?, isBackground: Bool, callbackFired: Bool, viewContext: AdViewContext) {
        if let report {
            tokenStore.storeFromRound(report, adType: .banner)

            if isBackground {
                sendAuctionReport(report, viewContext: viewContext)
            } else {
                finalizeAuctionInfo(from: report, viewContext: viewContext)
            }
        }
        if !isBackground, !callbackFired {
            handleNoFill(.noFill)
        }
        finalizeLoad(callbackFired: isBackground || callbackFired)
    }

    private func handleNoFill(_ error: SdkError) {
        Logger.vManagerBanner("handleNoFill: \(error.description)")
        DispatchQueue.main.async { [self] in
            state = .idle
            delegate?.adManager(self, didFailToLoad: error, auctionInfo: auctionInfo)
        }
    }

    private func finalizeLoad(callbackFired: Bool) {
        loadingState = .idle

        if slots.slotCount < 2 {
            Logger.vManagerBanner("finalizeLoad: slotCount=\(slots.slotCount) < 2 → scheduleAutoRestart")
            scheduleAutoRestart()
        } else {
            Logger.vManagerBanner("finalizeLoad: slots full → reset retry")
            retry.reset()
        }
        Logger.vManagerBanner("finalizeLoad done: slots=\(slots.description), callbackFired=\(callbackFired)")
    }

    private func deliverCachedBid(_ entry: CachedBid, viewContext: AdViewContext) {
        guard let impression: AdViewImpression = entry.buildImpressionController() else {
            return
        }
        entry.observeRevenue(adRevenueObserver)
        VladimirSandbox.cache.confirm(entryID: entry.meta.entryID)
        state = .ready(impression: impression)

        attachDisplayedAdUnitToAuctionInfo(entry)
        let ad = entry.makeAd()
        DispatchQueue.main.async { [self] in
            delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
        }
    }

    private func refillSlotsIfNeeded() {
        guard slots.isFull == false else {
            return
        }
        onSlotVacancy()
    }

    private func onSlotVacancy() {
        guard loadingState == .idle, !retry.isPending else {
            return
        }
        Logger.vManagerBanner("onSlotVacancy → scheduleAutoRestart")
        scheduleAutoRestart()
    }

    private func scheduleAutoRestart() {
        retry.schedule { [weak self] in
            guard let self, let viewContext = lastViewContext else {
                return
            }
            self.startLoad(pricefloor: self.lastPricefloor, viewContext: viewContext, auctionKey: self.lastAuctionKey, isBackground: true)
        }
    }

    private func cancelAutoRestart() {
        Logger.vManagerBanner("cancelAutoRestart")
        retry.cancel()
    }
}

private extension VBannerAdManager {
    func makeEngine(viewContext: AdViewContext) -> VAuctionEngine<BannerAdTypeContext> {
        let bannerContext = BannerAdTypeContext(viewContext: viewContext)
        return VAuctionEngine(
            context: bannerContext,
            adapters: bannerContext.adViewAdapters(viewContext: viewContext),
            sdk: sdk,
            extras: extras,
            adRevenueObserver: adRevenueObserver,
            buildAuction: { [adaptersRepository = sdk.adaptersRepository, adRevenueObserver] provider, observer, configuration in
                VAuctionController<BannerAdTypeContext> { (builder: AdViewConcurrentAuctionControllerBuilder) in
                    builder.withAdaptersRepository(adaptersRepository)
                    builder.withAdUnitProvider(provider)
                    builder.withAuctionObserver(observer)
                    builder.withPricefloor(configuration.pricefloor)
                    builder.withAdRevenueObserver(adRevenueObserver)
                    builder.withContext(bannerContext)
                    builder.withViewContext(viewContext)
                    builder.withAuctionConfiguration(configuration)
                }
            }
        )
    }

    func attachDisplayedAdUnitToAuctionInfo(_ entry: CachedBid) {
        let demandReportModel = AuctionDemandReportModel.winner(entry)
        if auctionInfo.adUnits == nil {
            auctionInfo.adUnits = []
        }
        auctionInfo.adUnits?.append(DefaultAdUnitInfo(demandReportModel))
    }

    func finalizeAuctionInfo(from report: any AuctionReport, viewContext: AdViewContext) {
        sendAuctionReport(report, viewContext: viewContext)
        var allDemands = report.round.demands
        if let biddingDemands = report.round.bidding?.demands {
            allDemands.append(contentsOf: biddingDemands)
        }
        auctionInfo.adUnits = allDemands.compactMap { DefaultAdUnitInfo($0) }

        let wins = allDemands.filter { $0.status.isWin }.map { "\($0.demandId)@\(String(format: "%.2f", $0.bid?.price ?? 0))" }
        let losses = allDemands.filter { !$0.status.isWin }.map { "\($0.demandId):\($0.status.stringValue)" }
        Logger.vManagerBanner("report: \(allDemands.count) demands, wins=\(wins), losses=\(losses)")
    }

    func makeCachedBid(_ bid: BidType, configuration: AuctionConfiguration, viewContext: AdViewContext) -> CachedBid {
        let context = BannerAdTypeContext(viewContext: viewContext)
        let meta = CachedBid.Meta.cached(withTTL: 60 * 10, consentHash: "v0")
        return CachedBid(
            meta: meta,
            payload: .init(
                adType: .banner,
                demandID: bid.adUnit.demandId,
                auctionID: configuration.auctionId,
                price: bid.price,
                bid: DummyBid(bid),
                adUnit: DummyAdUnit(bid.adUnit)
            ),
            makeAd: { AdContainer(bid: bid) },
            makeImpressionController: { AdViewImpression(bid: bid.unwrapped(), format: context.format) as AnyObject },
            observeRevenue: { observer in observer.observe(bid) }
        )
    }
}
