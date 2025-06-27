//
//  BannerManager.swift
//  Bidon
//
//  Created by Bidon Team on 26.08.2022.
//

import Foundation
import UIKit


protocol BannerAdManagerDelegate: AnyObject {
    func adManager(_ adManager: BannerAdManager, didFailToLoad error: SdkError, auctionInfo: AuctionInfo)
    func adManager(_ adManager: BannerAdManager, didLoad ad: Ad, auctionInfo: AuctionInfo)
}


final class BannerAdManager: NSObject {
    private typealias AuctionInfo = AuctionRequest.ResponseBody

    fileprivate typealias AuctionControllerType = ConcurrentAuctionController<BannerAdTypeContext>

    fileprivate enum State {
        case idle
        case preparing
        case auction(controller: AuctionControllerType)
        case ready(impression: AdViewImpression)
    }

    @Injected(\.networkManager)
    private var networkManager: NetworkManager

    @Injected(\.sdk)
    private var sdk: Sdk

    private var state: State = .idle

    let adRevenueObserver: AdRevenueObserver

    let placement: String

    weak var delegate: BannerAdManagerDelegate?

    var impression: AdViewImpression? {
        switch state {
        case .ready(let imp): return imp
        default: return nil
        }
    }

    var extras: [String: AnyHashable] = [:]

    var demandsTokensManager: DemandsTokensManager<BannerAdTypeContext>?
    private let auctionInfo: Bidon.AuctionInfo = DefaultAuctionInfo()
    private var isCanceled = false
    private var auctionStartTimestamp: TimeInterval?

    init(
        placement: String,
        adRevenueObserver: AdRevenueObserver
    ) {

        self.placement = placement
        self.adRevenueObserver = adRevenueObserver
        super.init()
    }

    func prepareForReuse() {
        state = .idle
    }

    func loadAd(
        pricefloor: Price,
        viewContext: AdViewContext,
        auctionKey: String?
    ) {
        guard BidonSdk.isInitialized else {
            Logger.warning("Bidon SDK is not initialized or failed initialization. Initialize SDK first")
            delegate?.adManager(self, didFailToLoad: .message("SDK is not initialized"), auctionInfo: auctionInfo)
            return
        }

        guard state.isIdle else {
            Logger.warning("Banner ad manager is not idle. Loading attempt is prohibited.")
            return
        }

        fetchAuctionInfo(
            pricefloor: pricefloor,
            viewContext: viewContext,
            auctionKey: auctionKey
        )
    }

    private func fetchAuctionInfo(
        pricefloor: Price,
        viewContext: AdViewContext,
        auctionKey: String?
    ) {
        auctionInfo.auctionPricefloor = NSNumber(value: pricefloor)
        state = .preparing
        auctionStartTimestamp = Date.timestamp(.wall, units: .milliseconds)

        let context = BannerAdTypeContext(viewContext: viewContext)

        guard let initializationParameters = ConfigParametersStorage.adaptersInitializationParameters else {
            self.state = .idle
            Logger.warning("No adapters were found")
            self.delegate?.adManager(self, didFailToLoad: SdkError.message("No adapters were found"), auctionInfo: auctionInfo)
            return
        }

        let demands = initializationParameters.adapters.map({ $0.demandId })

        let builder = DemandsTokensManagerBuilder<BannerAdTypeContext>()
        builder.withDemands(demands)
        builder.withAdapters(context.adViewAdapters(viewContext: viewContext))
        builder.withTimeout(ConfigParametersStorage.tokenTimeout ?? Constants.Timeout.defaultTokensTimeout)
        builder.withContext(context)

        let demandsManager = DemandsTokensManager<BannerAdTypeContext>(builder: builder)
        self.demandsTokensManager = demandsManager

        demandsManager.load(initializationParameters: initializationParameters) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let tokens):
                self.perfornAuctionRequest(tokens: tokens, pricefloor: pricefloor, auctionKey: auctionKey, viewContext: viewContext)
            case .failure(let error):
                self.state = .idle
                Logger.warning("Fullscreen ad manager did fail to load ad with error: \(error)")
                self.delegate?.adManager(self, didFailToLoad: SdkError(error), auctionInfo: auctionInfo)
            }
        }
    }

    private func perfornAuctionRequest(tokens: [BiddingDemandToken], pricefloor: Price, auctionKey: String?, viewContext: AdViewContext) {
        let context = BannerAdTypeContext(viewContext: viewContext)

        let request = context.auctionRequest { builder in
            builder.withAuctionKey(auctionKey)
            builder.withBiddingTokens(tokens)
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withAuctionId(UUID().uuidString)
            builder.withPricefloor(pricefloor)
            builder.withExt(extras)
        }

        Logger.verbose("Banner ad manager performs request: \(request)")

        networkManager.perform(
            request: request
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.auctionInfo.auctionId = response.auctionId
                self.auctionInfo.auctionConfigurationId = NSNumber(value: response.auctionConfigurationId)
                self.auctionInfo.auctionConfigurationUid = response.auctionConfigurationUid
                self.auctionInfo.noBids = response.noBids?.compactMap({ DefaultAdUnitInfo($0) })
                self.auctionInfo.timeout = NSNumber(value: response.auctionTimeout)

                self.sdk.updateSegmentIfNeeded(response.segment)
                self.performAuction(
                    auctionInfo: response,
                    tokens: tokens,
                    viewContext: viewContext
                )
            case .failure(let error):
                Logger.warning("Banner ad manager did fail to load ad with error: \(error)")
                self.state = .idle
                self.delegate?.adManager(self, didFailToLoad: SdkError(error), auctionInfo: auctionInfo)
            }
        }
    }

    private func performAuction(
        auctionInfo: AuctionInfo,
        tokens: [BiddingDemandToken],
        viewContext: AdViewContext
    ) {
        if isCanceled {
            return
        }
        Logger.verbose("Banner ad manager will start auction: \(auctionInfo)")

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

        state = .auction(controller: auction)

        auction.load { [unowned observer, weak self] result in
            guard let self = self else { return }

            self.sendAuctionReport(observer.report, viewContext: viewContext)

            var allDemands = observer.report.round.demands
            if let biddingDemands = observer.report.round.bidding?.demands {
                allDemands += biddingDemands
            }
            self.auctionInfo.adUnits = allDemands.compactMap({ DefaultAdUnitInfo($0) })

            switch result {
            case .success(let bid):
                adRevenueObserver.observe(bid)
                let impression = AdViewImpression(
                    bid: bid.unwrapped(),
                    format: context.format
                )
                self.state = .ready(impression: impression)

                let ad = AdContainer(bid: bid)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                }
            case .failure(let error):
                self.state = .idle
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                }
            }
        }
    }

    private func sendAuctionReport<T: AuctionReport>(_ report: T, viewContext: AdViewContext) {
        let context = BannerAdTypeContext(viewContext: viewContext)

        let request = context.statisticRequest { builder in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras)
            builder.withAuctionReport(report)
        }

        networkManager.perform(request: request) { result in
            Logger.debug("Sent statistics with result: \(result)")
        }
    }

    func notifyWin(viewContext: AdViewContext) {
        switch state {
        case .ready(var impression):
            // win notification just sends
            // a corresponding request
            // we need to mark impression as notified
            // regardless of whether a request was sent
            guard impression.isTrackingAllowed(.win) else { return }
            defer {
                impression.markTrackedIfNeeded(.win)
                state = .ready(impression: impression)
            }

            guard impression.auctionConfiguration.isExternalNotificationsEnabled else { return }

            let context = BannerAdTypeContext(viewContext: viewContext)

            let request = context.notificationRequest { builder in
                builder.withRoute(.win)
                builder.withEnvironmentRepository(sdk.environmentRepository)
                builder.withTestMode(sdk.isTestMode)
                builder.withExt(extras)
                builder.withImpression(impression)
            }

            networkManager.perform(request: request) { result in
                Logger.debug("Sent win with result: \(result)")
            }
        default:
            break
        }
    }

    func notifyLoss(
        winner demandId: String,
        eCPM: Price,
        viewContext: AdViewContext
    ) {
        switch state {
        case .preparing:
            isCanceled = true
            state = .idle
            delegate?.adManager(self, didFailToLoad: .cancelled, auctionInfo: auctionInfo)
        case .auction(let controller):
            controller.cancel()
        case .ready(let impression):
            // Invalidate a bid only in case the SDK doesn't
            // received win/loss yet,
            // isExternalNotificationsEnabled applies only
            // for request logic
            guard impression.isTrackingAllowed(.loss) else { return }
            defer { state = .idle }

            guard impression.auctionConfiguration.isExternalNotificationsEnabled else { return }

            let context = BannerAdTypeContext(viewContext: viewContext)
            let request = context.notificationRequest { builder in
                builder.withRoute(.loss)
                builder.withEnvironmentRepository(sdk.environmentRepository)
                builder.withTestMode(sdk.isTestMode)
                builder.withExt(extras)
                builder.withImpression(impression)
                builder.withExternalWinner(demandId: demandId, price: eCPM)
            }

            networkManager.perform(request: request) { result in
                Logger.debug("Sent loss with result: \(result)")
            }
        default:
            break
        }
    }
}


private extension BannerAdManager.State {
    var isIdle: Bool {
        switch self {
        case .idle: return true
        default: return false
        }
    }
}
