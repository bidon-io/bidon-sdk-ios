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
        case ready(bid: AdViewBid)
    }
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private var state: State = .idle
    
    let adRevenueObserver: AdRevenueObserver
    
    let placement: String
    
    weak var delegate: BannerAdManagerDelegate?
    
    var bid: AdViewBid? {
        switch state {
        case .ready(let bid): return bid
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
                let unwrapped = bid.unwrapped()
                self.state = .ready(bid: unwrapped)
                
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
