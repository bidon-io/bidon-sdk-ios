//
//  BannerManager.swift
//  Bidon
//
//  Created by Bidon Team on 26.08.2022.
//

import Foundation
import UIKit


protocol BannerAdManagerDelegate: AnyObject {
    func adManager(_ adManager: BannerAdManager, didFailToLoad error: SdkError)
    func adManager(_ adManager: BannerAdManager, didLoad ad: Ad)
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
        viewContext: AdViewContext
    ) {
        guard state.isIdle else {
            Logger.warning("Banner ad manager is not idle. Loading attempt is prohibited.")
            return
        }
        
        fetchAuctionInfo(
            pricefloor: pricefloor,
            viewContext: viewContext
        )
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
            guard impression.metadata.isExternalNotificationsEnabled else { return }
                  
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
            state = .idle
            delegate?.adManager(self, didFailToLoad: .cancelled)
        case .auction(let controller):
            controller.cancel()
        case .ready(let impression):
            // Invalidate a bid only in case the SDK doesn't
            // received win/loss yet,
            // isExternalNotificationsEnabled applies only
            // for request logic
            guard impression.isTrackingAllowed(.loss) else { return }
            defer { state = .idle }
            guard impression.metadata.isExternalNotificationsEnabled else { return }
                 
            let context = BannerAdTypeContext(viewContext: viewContext)
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
    
    private func fetchAuctionInfo(
        pricefloor: Price,
        viewContext: AdViewContext
    ) {
        state = .preparing
        
        let context = BannerAdTypeContext(viewContext: viewContext)
        
        let request = context.auctionRequest { builder in
            builder.withPlacement(placement)
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
                self.sdk.updateSegmentIfNeeded(response.segment)
                self.performAuction(
                    auctionInfo: response,
                    viewContext: viewContext
                )
            case .failure(let error):
                Logger.warning("Banner ad manager did fail to load ad with error: \(error)")
                self.state = .idle
                self.delegate?.adManager(self, didFailToLoad: SdkError(error))
            }
        }
    }
    
    private func performAuction(
        auctionInfo: AuctionInfo,
        viewContext: AdViewContext
    ) {
        Logger.verbose("Banner ad manager will start auction: \(auctionInfo)")
        
        let metadata = AuctionMetadata(
            id: auctionInfo.auctionId,
            configuration: auctionInfo.auctionConfigurationId,
            configurationUid: auctionInfo.auctionConfigurationUid,
            isExternalNotificationsEnabled: auctionInfo.externalWinNotifications
        )
        
        let observer = BaseMediationObserver(
            auctionId: auctionInfo.auctionId,
            adType: .banner
        )
        
        let context = BannerAdTypeContext(viewContext: viewContext)
        let elector = StrictAuctionLineItemElector(lineItems: auctionInfo.lineItems)
        
        let auction = AuctionControllerType { (builder: AdViewConcurrentAuctionControllerBuilder) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withRounds(auctionInfo.rounds)
            builder.withElector(elector)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withContext(context)
            builder.withViewContext(viewContext)
            builder.withMediationObserver(observer)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withMetadata(metadata)
        }
        
        auction.load { [unowned observer, weak self] result in
            guard let self = self else { return }
            
            self.sendMediationAttemptReport(
                observer.report,
                metadata: metadata
            )

            switch result {
            case .success(let bid):
                let impression = AdViewImpression(
                    bid: bid.unwrapped(),
                    format: context.format
                )
                self.state = .ready(impression: impression)
                
                let ad = AdContainer(bid: bid)
                self.delegate?.adManager(self, didLoad: ad)
            case .failure(let error):
                self.state = .idle
                self.delegate?.adManager(self, didFailToLoad: error)
            }
        }
        
        state = .auction(controller: auction)
    }
    
    private func sendMediationAttemptReport<T: MediationAttemptReport>(
        _ report: T,
        metadata: AuctionMetadata
    ) {
        let request = StatisticRequest { builder in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras)
            builder.withAdType(.banner)
            builder.withMediationReport(report, metadata: metadata)
        }
        
        networkManager.perform(request: request) { result in
            Logger.debug("Sent statistics with result: \(result)")
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
