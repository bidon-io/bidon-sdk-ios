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
    var auction: ZhenyaAuctionControllerType?

    override var isReady: Bool {
        return Cacher.interstitialStorage.peek() != nil
    }

    override func loadAd(pricefloor: Price, auctionKey: String?) {
        auctionInfo = DefaultAuctionInfo()
        Logger.debug("""
        [ZhenyaAdManager] loadAd called
        - pricefloor: \(pricefloor)
        - auctionKey: \(auctionKey ?? "nil")
        - delegate: \(self.delegate != nil ? "exists" : "NIL ⚠️")
        - cache has item: \(Cacher.interstitialStorage.peek() != nil)
        """)
        
        // If cache has a bid container that already meets the floor — use it.
        if let ad = Cacher.interstitialStorage.peek()?.ad as? BidContainer, ad.price >= pricefloor {
            let controller = ImpressionControllerType(
                bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>
            )
            controller.delegate = self
            self.state = .ready(controller: controller)
            
            let demandReportModel = AuctionDemandReportModel(
                demandId: ad.bid.adUnit.demandId,
                status: .win,
                bid: DummyBid(ad.bid),
                adUnit: DummyAdUnit(ad.bid.adUnit),
                startTimestamp: 0,
                finishTimestamp: 0,
                tokenStartTimestamp: 0,
                tokenFinishTimestamp: 0
            )
            
            if self.auctionInfo.adUnits == nil {
                self.auctionInfo.adUnits = []
            }
            self.auctionInfo.adUnits?.append(DefaultAdUnitInfo(demandReportModel))
            
            Logger.debug("[ZhenyaAdManager] Using cached ad, delegate: \(self.delegate != nil ? "exists" : "NIL ⚠️")")
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
            return
        }

        super.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }

    override func show(from rootViewController: UIViewController) {
        switch state {
        case .ready:
            guard let ad = Cacher.interstitialStorage.popFirst()?.ad as? BidContainer else { return }

            let bid = ad.bid
            let imprController = ImpressionControllerType(
                bid: bid as! BidModel<AdTypeContextType.DemandProviderType>
            )
            imprController.delegate = self

            state = .impression(controller: imprController)
            imprController.show(from: rootViewController)

        default:
            delegate?.adManager(self, didFailToPresent: nil, error: .internalInconsistency)
        }
    }

    override func performAuction(
        _ auctionInfo: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>.AuctionInfo,
        tokens: [BiddingDemandToken]
    ) {
        Logger.debug("""
        [ZhenyaAdManager] performAuction called
        - delegate at START: \(self.delegate != nil ? "exists" : "NIL ⚠️")
        """)
        
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
        
        Cacher.interstitialStorage.beginIteration()

        // single-load callback: insert into cache + report refill outcome
        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }

            let ad = BidContainer(bid: bid)
            let item = Item(
                ad: ad,
                manager: self as! ZhenyaAdManager<
                    InterstitialAdTypeContext,
                    InterstitialConcurrentAuctionControllerBuilder,
                    InterstitialImpressionController,
                    InterstitialAdaptersFetcher
                >
            )

            let inserted = Cacher.interstitialStorage.insert(item, sticky: self.isFirstLoad)
            if inserted {
                self.adRevenueObserver.observe(bid)
            }

            if self.isFirstLoad {
                let controller = ImpressionControllerType(bid: bid)
                controller.delegate = self
                self.state = .ready(controller: controller)

                Logger.debug("""
                [ZhenyaAdManager] Before DispatchQueue.main.async
                - delegate: \(self.delegate != nil ? "exists" : "NIL ⚠️")
                - self: \(self)
                """)
                
                let demandReportModel = AuctionDemandReportModel(
                    demandId: ad.bid.adUnit.demandId,
                    status: .win,
                    bid: DummyBid(ad.bid),
                    adUnit: DummyAdUnit(ad.bid.adUnit),
                    startTimestamp: 0,
                    finishTimestamp: 0,
                    tokenStartTimestamp: 0,
                    tokenFinishTimestamp: 0
                )
                if self.auctionInfo.adUnits == nil {
                    self.auctionInfo.adUnits = []
                }
                self.auctionInfo.adUnits?.append(DefaultAdUnitInfo(demandReportModel))

                DispatchQueue.main.async { [weak self] in
                    guard let self else { 
                        Logger.error("[ZhenyaAdManager] self is nil in DispatchQueue.main.async!")
                        return 
                    }
                    
                    self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                }
            }

            self.isFirstLoad = false
        }

        auction.load { [unowned observer, weak self] result in
            guard let self else { return }

            self.sendAuctionReport(observer.report)

            switch result {
            case .success:
                // If your auction can end "success" without any bids delivered via `singleLoadCompletion`,
                // you should call `.noFill` here. Otherwise, keep as-is.
                break

            case .failure(let error):
                self.state = .idle
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                }
            }

            self.auction = nil
        }

        self.auction = auction
    }
}
