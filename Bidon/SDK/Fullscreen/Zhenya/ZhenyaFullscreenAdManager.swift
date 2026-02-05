//
//  Zhenya.swift
//  Bidon
//

import Foundation
import UIKit

final class ZhenyaAdManager<
    AdTypeContextType,
    AuctionControllerBuilderType,
    ImpressionControllerType,
    AdaptersFetcherType
>: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>
where
    AdTypeContextType: AdTypeContext,
    AuctionControllerBuilderType: BaseConcurrentAuctionControllerBuilder<AdTypeContextType>,
    ImpressionControllerType: FullscreenImpressionController,
    ImpressionControllerType.BidType == BidModel<AdTypeContextType.DemandProviderType>,
    AdaptersFetcherType: AdaptersFetcher<AdTypeContextType> {
        
        var isFirstLoad: Bool = true
        
        override var isReady: Bool {
            return Cacher.storage.peek() != nil
        }
        
        override func loadAd(pricefloor: Price, auctionKey: String?) {
            if let ad = Cacher.storage.peek()?.ad as? BidContainer, ad.price >= pricefloor {
                let controller = ImpressionControllerType(bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>)
                controller.delegate = self
                self.state = .ready(controller: controller)
                
                self.delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
            } else {
                super.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
            }
        }
        
        override func show(from rootViewController: UIViewController) {
            guard let ad = Cacher.storage.popFirst()?.ad as? BidContainer else {
                return
            }
            let bid = ad.bid
            let imprController = ImpressionControllerType(bid: bid as! BidModel<AdTypeContextType.DemandProviderType>)
            imprController.delegate = self
            
            switch state {
            case .ready:
                state = .impression(controller: imprController)
                imprController.show(from: rootViewController)
            default:
                delegate?.adManager(self, didFailToPresent: nil, error: .internalInconsistency)
            }
        }
        
        override func performAuction(_ auctionInfo: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>.AuctionInfo, tokens: [BiddingDemandToken]) {
            
            isFirstLoad = true
            
            Logger.verbose("Fullscreen ad manager will start auction: \(auctionInfo)")

            let configuration = AuctionConfiguration(auction: auctionInfo, tokens: tokens)

            let observer = BaseAuctionObserver(
                configuration: configuration,
                adType: context.adType
            )
            if let auctionStartTimestamp {
                observer.log(StartAuctionEvent(startTimestamp: auctionStartTimestamp))
            }

            let provider = DefaultAdUnitProvider(adUnits: auctionInfo.adUnits)

            let auction = ZhenyaAuctionControllerType { (builder: AuctionControllerBuilderType) in
                builder.withAdaptersRepository(sdk.adaptersRepository)
                builder.withAdUnitProvider(provider)
                builder.withAuctionObserver(observer)
                builder.withPricefloor(auctionInfo.pricefloor)
                builder.withAdRevenueObserver(self.adRevenueObserver)
                builder.withContext(context)
                builder.withAuctionConfiguration(configuration)
            }

            state = .auction(controller: auction)
            auction.singleLoadCompletion = { [weak self] bid in
                guard let self else { return }
                let ad = BidContainer(bid: bid)
                let item = Item(ad: ad, manager: self as! ZhenyaAdManager<InterstitialAdTypeContext, InterstitialConcurrentAuctionControllerBuilder, InterstitialImpressionController, InterstitialAdaptersFetcher>)
                if Cacher.storage.insert(item) == true {
                    adRevenueObserver.observe(bid)
                }
                
                if isFirstLoad {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                    }
                }
                
                self.isFirstLoad = false
            }

            auction.load { [unowned observer, weak self] result in
                guard let self = self else { return }

                self.sendAuctionReport(observer.report)
                var allDemands = observer.report.round.demands
                if let biddingDemands = observer.report.round.bidding?.demands {
                    allDemands += biddingDemands
                }
                self.auctionInfo.adUnits = allDemands.compactMap({ DefaultAdUnitInfo($0) })

                switch result {
                case .success(let bid):
                    let controller = ImpressionControllerType(bid: bid)
                    controller.delegate = self
                    self.state = .ready(controller: controller)
                    let ad = AdContainer(bid: bid)

                case .failure(let error):
                    self.state = .idle
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                    }
                }
            }
        }
}
