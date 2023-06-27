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
        case ready(keeper: BidKeeper<BidType>)
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
        case .ready(let keeper):
            let impression = ImpressionControllerType(bid: keeper.bid).impression
            
            guard
                impression.isTrackingAllowed(.win),
                impression.metadata.isExternalNotificationsEnabled
            else { return }
                  
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
        eCPM: Price
    ) {
        switch state {
        case .ready(let keeper):
            let impression = ImpressionControllerType(bid: keeper.bid).impression

            defer { state = .idle }
            
            guard
                impression.isTrackingAllowed(.loss),
                impression.metadata.isExternalNotificationsEnabled
            else { return }
                  
            let request = context.notificationRequest { builder in
                builder.withRoute(.loss)
                builder.withEnvironmentRepository(sdk.environmentRepository)
                builder.withTestMode(sdk.isTestMode)
                builder.withExt(extras)
                builder.withImpression(impression)
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
            
            switch result {
            case .success(let response):
                self.sdk.updateSegmentIfNeeded(response.segment)
                self.performAuction(response)
            case .failure(let error):
                self.state = .idle
                Logger.warning("Fullscreen ad manager did fail to load ad with error: \(error)")
                self.delegate?.adManager(self, didFailToLoad: SdkError(error))
            }
        }
    }
    
    func show(from rootViewController: UIViewController) {
        switch state {
        case .ready(let keeper):
            let controller = ImpressionControllerType(bid: keeper.bid)
            controller.delegate = self
            state = .impression(controller: controller)
            controller.show(from: rootViewController)
        default:
            delegate?.adManager(self, didFailToPresent: nil, error: .internalInconsistency)
        }
    }
    
    private func performAuction(_ auctionInfo: AuctionInfo) {
        Logger.verbose("Fullscreen ad manager will start auction: \(auctionInfo)")
        
        let metadata = AuctionMetadata(
            id: auctionInfo.auctionId,
            configuration: auctionInfo.auctionConfigurationId,
            isExternalNotificationsEnabled: auctionInfo.externalWinNotifications
        )
        
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
            builder.withMetadata(metadata)
        }
        
        auction.load { [unowned observer, weak self] result in
            guard let self = self else { return }
            
            self.sendAuctionStatistics(
                observer.report,
                metadata: metadata
            )
            
            switch result {
            case .success(let bid):
                let keeper = BidKeeper(bid: bid) { [weak self] expiredBid in
                    self?.expire(bid: expiredBid)
                }
                
                self.state = .ready(keeper: keeper)
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
        metadata: AuctionMetadata
    ) {
        let request = StatisticRequest { builder in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras)
            builder.withAdType(context.adType)
            builder.withMediationReport(report, metadata: metadata)
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
    
    private func expire(bid: BidType) {
        state = .idle
        let container = AdContainer(bid: bid)
        delegate?.adManager(self, didExpire: container)
    }
}


extension BaseFullscreenAdManager: FullscreenImpressionControllerDelegate {
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
        case .ready(let keeper):
            return [AdContainer(bid: keeper.bid)]
        case .impression(let controller):
            return [AdContainer(impression: controller.impression)]
        default: return []
        }
    }
}
