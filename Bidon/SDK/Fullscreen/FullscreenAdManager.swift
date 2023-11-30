//
//  RewardedAd.swift
//  Bidon
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import UIKit


protocol FullscreenAdManager: AnyObject {
    var isReady: Bool { get }
}


protocol FullscreenAdManagerDelegate: AnyObject {
    func adManager(_ adManager: FullscreenAdManager, didFailToLoad error: SdkError)
    func adManager(_ adManager: FullscreenAdManager, didLoad ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, didFailToPresent ad: Ad?, error: SdkError)
    func adManager(_ adManager: FullscreenAdManager, didExpire ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, willPresent ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, didHide ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, didClick ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, didReward reward: Reward, ad: Ad)
    func adManager(_ adManager: FullscreenAdManager, didPayRevenue revenue: AdRevenue, ad: Ad)
}


final class BaseFullscreenAdManager <AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType>: NSObject, FullscreenAdManager where
AdTypeContextType: AdTypeContext,
AuctionControllerBuilderType: BaseConcurrentAuctionControllerBuilder<AdTypeContextType>,
ImpressionControllerType: FullscreenImpressionController,
ImpressionControllerType.BidType == BidModel<AdTypeContextType.DemandProviderType> {
    
    fileprivate typealias BidType = BidModel<AdTypeContextType.DemandProviderType>
    fileprivate typealias AuctionControllerType = ConcurrentAuctionController<AdTypeContextType>
    
    private typealias AuctionInfo = AuctionRequest.ResponseBody
    
    fileprivate enum State {
        case idle
        case preparing
        case auction(controller: AuctionControllerType)
        case ready(controller: ImpressionControllerType)
        case impression(controller: ImpressionControllerType)
    }
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private var state: State = .idle
    
    private weak var delegate: (any FullscreenAdManagerDelegate)?
    
    private let placement: String
    private let context: AdTypeContextType
    
    private lazy var adRevenueObserver: AdRevenueObserver = {
        let observer = BaseAdRevenueObserver()
        
        observer.ads = { [weak self] in
            guard let self = self else { return [] }
            return self.state.ads
        }
        
        observer.onRegisterAdRevenue = { [weak self] ad, revenue in
            guard let self = self else { return }
            self.delegate?.adManager(self, didPayRevenue: revenue, ad: ad)
        }
        
        return observer
    }()
    
    var isReady: Bool {
        switch state {
        case .ready: return true
        default: return false
        }
    }
    
    lazy var extras: [String : AnyHashable] = [:]
    
    init(
        context: AdTypeContextType,
        placement: String,
        delegate: (any FullscreenAdManagerDelegate)?
    ) {
        self.delegate = delegate
        self.context = context
        self.placement = placement
        super.init()
    }
    
    func loadAd(pricefloor: Price) {
        guard state.isIdle else {
            Logger.warning("Fullscreen ad manager is not idle. Loading attempt is prohibited.")
            return
        }
        
        fetchAuctionInfo(pricefloor)
    }
    
    func notifyWin() {
        switch state {
        case .ready(let controller):
            // win notification just sends
            // a corresponding request
            // we need to mark impression as notified
            // regardless of whether a request was sent
            guard controller.impression.isTrackingAllowed(.win) else { return }
            defer { controller.impression.markTrackedIfNeeded(.win) }
            guard controller.impression.auctionConfiguration.isExternalNotificationsEnabled else { return }
                  
            let request = context.notificationRequest { builder in
                builder.withRoute(.win)
                builder.withEnvironmentRepository(sdk.environmentRepository)
                builder.withTestMode(sdk.isTestMode)
                builder.withExt(extras)
                builder.withImpression(controller.impression)
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
        eCPM: Price
    ) {
        switch state {
        case .preparing:
            state = .idle
            delegate?.adManager(self, didFailToLoad: .cancelled)
        case .auction(let controller):
            controller.cancel()
        case .ready(let controller):
            // Invalidate a bid only in case the SDK doesn't
            // received win/loss yet,
            // isExternalNotificationsEnabled applies only
            // for request logic
            guard controller.impression.isTrackingAllowed(.loss) else { return }
            defer {
                controller.impression.markTrackedIfNeeded(.loss)
                state = .idle
            }
            guard controller.impression.auctionConfiguration.isExternalNotificationsEnabled else { return }
            
            let request = context.notificationRequest { builder in
                builder.withRoute(.loss)
                builder.withEnvironmentRepository(sdk.environmentRepository)
                builder.withTestMode(sdk.isTestMode)
                builder.withExt(extras)
                builder.withImpression(controller.impression)
                builder.withExternalWinner(demandId: demandId, eCPM: eCPM)
            }

            networkManager.perform(request: request) { result in
                Logger.debug("Sent loss with result: \(result)")
            }
        default:
            break
        }
    }
    
    private func fetchAuctionInfo(_ pricefloor: Price) {
        state = .preparing
        
        let request = context.auctionRequest { builder in
            builder.withPlacement(placement)
            builder.withPricefloor(pricefloor)
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withAuctionId(UUID().uuidString)
            builder.withExt(extras)
        }
        
        Logger.verbose("Fullscreen ad manager performs request: \(request)")
        
        networkManager.perform(
            request: request
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch (self.state, result) {
            case (.preparing, .success(let response)):
                self.sdk.updateSegmentIfNeeded(response.segment)
                self.performAuction(response)
            case (.preparing, .failure(let error)):
                self.state = .idle
                Logger.warning("Fullscreen ad manager did fail to load ad with error: \(error)")
                self.delegate?.adManager(self, didFailToLoad: SdkError(error))
            default:
                break
            }
        }
    }
    
    func show(from rootViewController: UIViewController) {
        switch state {
        case .ready(let controller):
            state = .impression(controller: controller)
            controller.show(from: rootViewController)
        default:
            delegate?.adManager(self, didFailToPresent: nil, error: .internalInconsistency)
        }
    }
    
    private func performAuction(_ auctionInfo: AuctionInfo) {
        Logger.verbose("Fullscreen ad manager will start auction: \(auctionInfo)")
        
        let auctionConfiguration = AuctionConfiguration(auction: auctionInfo)
        
        let observer = BaseMediationObserver(
            auctionId: auctionInfo.auctionId,
            adType: context.adType
        )
        
        let elector = StrictAuctionLineItemElector(lineItems: auctionInfo.lineItems)
        
        let auction = AuctionControllerType { (builder: AuctionControllerBuilderType) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withRounds(auctionInfo.rounds)
            builder.withElector(elector)
            builder.withMediationObserver(observer)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withContext(context)
            builder.withAuctionConfiguration(auctionConfiguration)
        }
        
        auction.load { [unowned observer, weak self] result in
            guard let self = self else { return }
            
            self.sendAuctionStatistics(
                observer.report,
                auctionConfiguration: auctionConfiguration
            )
            
            switch result {
            case .success(let bid):
                let controller = ImpressionControllerType(bid: bid)
                controller.delegate = self
                self.state = .ready(controller: controller)
                let ad = AdContainer(bid: bid)
                
                self.delegate?.adManager(self, didLoad: ad)
            case .failure(let error):
                self.state = .idle
                self.delegate?.adManager(self, didFailToLoad: error)
            }
        }
        
        state = .auction(controller: auction)
    }
    
    private func sendAuctionStatistics<T: MediationAttemptReport>(
        _ report: T,
        auctionConfiguration: AuctionConfiguration
    ) {
        let request = context.statisticRequest { builder in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras)
            builder.withMediationReport(report, auctionConfiguration: auctionConfiguration)
        }
        
        networkManager.perform(request: request) { result in
            Logger.debug("Sent statistics with result: \(result)")
        }
    }
    
    private func sendImpressionIfNeeded(
        _ impression: inout Impression,
        path: Route
    ) {
        guard impression.isTrackingAllowed(path) else { return }
        
        let request = context.impressionRequest { builder in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras)
            builder.withImpression(impression)
            builder.withPath(path)
        }
        
        networkManager.perform(request: request) { result in
            Logger.debug("Sent impression action '\(path)' with result: \(result)")
        }
        
        impression.markTrackedIfNeeded(path)
    }
}


extension BaseFullscreenAdManager: FullscreenImpressionControllerDelegate {
    func didExpire(_ impression: inout Impression) {
        state = .idle
        let container = AdContainer(impression: impression)
        delegate?.adManager(self, didExpire: container)
    }
    
    func didFailToPresent(_ impression: inout Impression?, error: SdkError) {
        state = .idle
        
        let ad = impression.map(AdContainer.init)
        delegate?.adManager(self, didFailToPresent: ad, error: error)
    }
    
    func willPresent(_ impression: inout Impression) {
        sendImpressionIfNeeded(&impression, path: .show)
        
        let ad = AdContainer(impression: impression)
        delegate?.adManager(self, willPresent: ad)
    }
    
    func didHide(_ impression: inout Impression) {
        state = .idle
        
        let ad = AdContainer(impression: impression)
        delegate?.adManager(self, didHide: ad)
    }
    
    func didClick(_ impression: inout Impression) {
        sendImpressionIfNeeded(&impression, path: .click)
        
        let ad = AdContainer(impression: impression)
        delegate?.adManager(self, didClick: ad)
    }
    
    func didReceiveReward(_ reward: Reward, impression: inout Impression) {
        sendImpressionIfNeeded(&impression, path: .reward)
        
        let ad = AdContainer(impression: impression)
        delegate?.adManager(self, didReward: reward, ad: ad)
    }
}


private extension BaseFullscreenAdManager.State {
    var isIdle: Bool {
        switch self {
        case .idle: return true
        default: return false
        }
    }
    
    var ads: [Ad] {
        switch self {
        case .ready(let controller), .impression(let controller):
            return [AdContainer(impression: controller.impression)]
        default: return []
        }
    }
}
