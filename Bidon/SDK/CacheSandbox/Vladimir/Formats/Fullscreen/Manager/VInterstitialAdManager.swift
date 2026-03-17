//
//  VInterstitialAdManager.swift
//  Bidon
//

import Foundation

final class VInterstitialAdManager: InterstitialBaseManager {
    private let slots = VSlotManager(
        store: VladimirSandbox.cache,
        key: .interstitial()
    )

    private lazy var impressionProxy: CacheImpressionDelegateProxy = {
        let proxy = CacheImpressionDelegateProxy(cache: VladimirSandbox.cache)
        proxy.delegate = self
        return proxy
    }()

    private enum LoadingState {
        case idle
        case loading
    }
    
    private let retry = AuctionRetryStrategy(adType: .interstitial)
    private let tokenStore = VladimirSandbox.rtbTokenStore

    private var loadingState: LoadingState = .idle
    private var lastPricefloor: Price = .zero
    private var lastAuctionKey: String?
    
    private var engine: VAuctionEngine<InterstitialAdTypeContext>?

    override init(
        context: InterstitialAdTypeContext,
        delegate: FullscreenAdManagerDelegate?
    ) {
        super.init(context: context, delegate: delegate)
        slots.onVacancy = { [weak self]
            in self?.onSlotVacancy()
        }
        Logger.vManagerInter("init: slots=\(slots.description)")
    }
    
    override func loadAd(pricefloor: Price, auctionKey: String?) {
        auctionInfo = DefaultAuctionInfo()
        slots.runMaintenance()
        lastPricefloor = pricefloor
        lastAuctionKey = auctionKey

        if let slot1 = slots.slot1, slot1.payload.price >= pricefloor, let popped = slots.pop() {
            Logger.vManagerInter("loadAd: immediate hit \(popped.payload.demandID)@\(popped.payload.price.debugString)")
            deliverCachedBid(popped)
            refillSlotsIfNeeded()
            return
        }
        
        if slots.isFull, let primaryPrice = slots.primaryPrice, primaryPrice < pricefloor {
            slots.evictBackup()
            Logger.vManagerInter("loadAd: smart eviction (slot1 below floor)")
        }
        
        guard !slots.isFull else {
            Logger.vManagerInter("loadAd: slots full, skip load")
            return
        }
        
        guard loadingState == .idle else {
            Logger.vManagerInter("loadAd: already loading, skip")
            return
        }
        
        cancelAutoRestart()
        startLoad(pricefloor: pricefloor, auctionKey: auctionKey, isBackground: false)
    }

    private func startLoad(pricefloor: Price, auctionKey: String?, isBackground: Bool) {
        loadingState = .loading
        
        Logger.vManagerInter("startLoad: pricefloor=\(pricefloor.debugString), isBackground=\(isBackground)")
        
        var callbackFired = false
        let auctionEngine = makeEngine()
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
            let entry = makeCachedBid(bid, configuration: configuration)
            let primaryFilled = slots.insert(entry)
            retry.reset()

            Logger.vManagerInter("onBidLoaded: \(bid.adUnit.demandId)@\(bid.price.debugString), primaryFilled=\(primaryFilled), isBackground=\(isBackground), slots=\(slots.description)")

            if !isBackground && primaryFilled && !callbackFired {
                guard let popped = slots.pop() else {
                    return
                }
                callbackFired = true
                deliverCachedBid(popped)
            } else if !primaryFilled {
                Logger.vManagerInter("onBidLoaded: slot2 filled silently")
            }
            if slots.isFull {
                auctionEngine.stop()
            }
        }
        
        auctionEngine.onComplete = { [weak self] report in
            self?.handleAuction(report: report, isBackground: isBackground, callbackFired: callbackFired)
        }
        
        BidonSdk.addInitializationHandler { [weak self, auctionEngine] in
            guard let self else {
                return
            }
            guard BidonSdk.isInitialized else {
                Logger.warning("VInterstitialAdManager: SDK not initialized")
                self.loadingState = .idle
                if !isBackground {
                    self.delegate?.adManager(self, didFailToLoad: .message("SDK is not initialized"), auctionInfo: self.auctionInfo)
                }
                return
            }
            let startTimestamp: TimeInterval? = isBackground ? nil : Date.timestamp(.wall, units: .milliseconds)
            let cachedRTBTokens = self.tokenStore.consumeTokens(adType: .interstitial)

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
    
    private func handleAuction(report: (any AuctionReport)?, isBackground: Bool, callbackFired: Bool) {
        if let report {
            tokenStore.storeFromRound(report, adType: .interstitial)
            
            if isBackground {
                sendAuctionReport(report)
            } else {
                finalizeAuctionInfo(from: report)
            }
        }
        if !isBackground,  !callbackFired {
            handleNoFill(.noFill)
        }
        finalizeLoad(callbackFired: isBackground || callbackFired)
    }

    private func handleNoFill(_ error: SdkError) {
        Logger.vManagerInter("handleNoFill: \(error.description)")
        DispatchQueue.main.async { [self] in
            state = .idle
            delegate?.adManager(self, didFailToLoad: error, auctionInfo: auctionInfo)
        }
    }
    
    private func finalizeLoad(callbackFired: Bool) {
        loadingState = .idle

        if slots.slotCount < 2 {
            Logger.vManagerInter("finalizeLoad: slotCount=\(slots.slotCount) < 2 → scheduleAutoRestart")
            scheduleAutoRestart()
        } else {
            Logger.vManagerInter("finalizeLoad: slots full → reset retry")
            retry.reset()
        }
        Logger.vManagerInter("finalizeLoad done: slots=\(slots.description), callbackFired=\(callbackFired)")
    }

    private func deliverCachedBid(_ entry: CachedBid) {
        guard let controller: InterstitialImpressionController = entry.buildImpressionController() else {
            return
        }
        entry.observeRevenue(adRevenueObserver)
        impressionProxy.setCachedEntryId(entry.meta.entryID)
        impressionProxy.currentDemandID = entry.payload.demandID
        controller.delegate = impressionProxy
        state = .ready(controller: controller)
        
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
        Logger.vManagerInter("onSlotVacancy → scheduleAutoRestart")
        scheduleAutoRestart()
    }
    
    private func scheduleAutoRestart() {
        retry.schedule { [weak self] in
            guard let self else {
                return
            }
            self.startLoad(pricefloor: self.lastPricefloor, auctionKey: self.lastAuctionKey, isBackground: true)
        }
    }
    
    private func cancelAutoRestart() {
        retry.cancel()
    }
}

private extension VInterstitialAdManager {
    func makeEngine() -> VAuctionEngine<InterstitialAdTypeContext> {
        VAuctionEngine(
            context: context,
            adapters: context.fullscreenAdapters(),
            sdk: sdk,
            extras: extras,
            adRevenueObserver: adRevenueObserver,
            buildAuction: { [adaptersRepository = sdk.adaptersRepository, adRevenueObserver, context] provider, observer, configuration in
                VAuctionController<InterstitialAdTypeContext> { (builder: InterstitialConcurrentAuctionControllerBuilder) in
                    builder.withAdaptersRepository(adaptersRepository)
                    builder.withAdUnitProvider(provider)
                    builder.withAuctionObserver(observer)
                    builder.withPricefloor(configuration.pricefloor)
                    builder.withAdRevenueObserver(adRevenueObserver)
                    builder.withContext(context)
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

    func finalizeAuctionInfo(from report: any AuctionReport) {
        sendAuctionReport(report)
        var allDemands = report.round.demands
        if let biddingDemands = report.round.bidding?.demands {
            allDemands.append(contentsOf: biddingDemands)
        }
        auctionInfo.adUnits = allDemands.compactMap { DefaultAdUnitInfo($0) }

        let wins = allDemands.filter { $0.status.isWin }.map { "\($0.demandId)@\(String(format: "%.2f", $0.bid?.price ?? 0))" }
        let losses = allDemands.filter { !$0.status.isWin }.map { "\($0.demandId):\($0.status.stringValue)" }
        Logger.vManagerInter("report: \(allDemands.count) demands, wins=\(wins), losses=\(losses)")
    }

    func makeCachedBid(_ bid: BidType, configuration: AuctionConfiguration) -> CachedBid {
        let meta = CachedBid.Meta.cached(withTTL: 60 * 10, consentHash: "v0")
        return CachedBid(
            meta: meta,
            payload: .init(
                adType: .interstitial,
                demandID: bid.adUnit.demandId,
                auctionID: configuration.auctionId,
                price: bid.price,
                bid: DummyBid(bid),
                adUnit: DummyAdUnit(bid.adUnit)
            ),
            makeAd: { AdContainer(bid: bid) },
            makeImpressionController: { InterstitialImpressionController(bid: bid) },
            observeRevenue: { observer in observer.observe(bid) }
        )
    }
}
