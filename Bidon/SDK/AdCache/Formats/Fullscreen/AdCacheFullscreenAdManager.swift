//
//  AdCacheFullscreenAdManager.swift
//  Bidon
//

import Foundation
import UIKit

final class AdCacheAdManager<
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
    var auction: AdCacheAuctionControllerType?

    override var isReady: Bool {
        return Cacher.Main.interstitialStorage.peek() != nil || Cacher.Fallback.interstitialStorage.peek() != nil
    }

    override func loadAd(pricefloor: Price, auctionKey: String?) {
        auctionInfo = DefaultAuctionInfo()
        Logger.debug("[AdCache] loadAd | floor: \(pricefloor) | key: \(auctionKey ?? "default") | cached: \(Cacher.Main.interstitialStorage.peek() != nil)")
        
        // If cache has a bid container that already meets the floor — use it.
        if let ad = Cacher.Main.interstitialStorage.peek() as? BidContainer, ad.price >= pricefloor {
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
            
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
            return
        }

        super.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }

    override func show(from rootViewController: UIViewController) {
        switch state {
        case .ready:
            // main cache first, fallback cache second
            guard let ad = (Cacher.Main.interstitialStorage.popFirst()
                         ?? Cacher.Fallback.interstitialStorage.popFirst()) as? BidContainer
            else { return }

            let imprController = ImpressionControllerType(
                bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>
            )
            imprController.delegate = self

            state = .impression(controller: imprController)
            imprController.show(from: rootViewController)

        default:
            delegate?.adManager(self, didFailToPresent: nil, error: .internalInconsistency)
            state = .idle
        }
    }
        
    override func handlePerformAuctionRequestFailed(error: any Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let ad = Cacher.Fallback.interstitialStorage.peek() as? BidContainer, ad.price >= self.pricefloor {
                // Update auctionInfo: set WIN status for the cached ad
                if let index = self.auctionInfo.adUnits?.firstIndex(where: { $0.demandId == ad.bid.adUnit.demandId && $0.uid == ad.bid.adUnit.uid }),
                   let adUnitInfo = self.auctionInfo.adUnits?[index] as? DefaultAdUnitInfo {
                    adUnitInfo.status = DemandMediationStatus.win.stringValue
                } else {
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
                }
                let controller = ImpressionControllerType(bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>)
                controller.delegate = self
                self.state = .ready(controller: controller)
                
                self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
            } else {
                self.sendErrorToSuperclass(error: error)
            }
        }
    }
        
    func sendErrorToSuperclass(error: Error) {
        super.handlePerformAuctionRequestFailed(error: error)
    }

    override func performAuction(
        _ auctionInfo: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>.AuctionInfo,
        tokens: [BiddingDemandToken]
    ) {
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

        let auction = AdCacheAuctionControllerType { (builder: AuctionControllerBuilderType) in
            builder.withAdaptersRepository(sdk.adaptersRepository)
            builder.withAdUnitProvider(provider)
            builder.withAuctionObserver(observer)
            builder.withPricefloor(auctionInfo.pricefloor)
            builder.withAdRevenueObserver(self.adRevenueObserver)
            builder.withContext(context)
            builder.withAuctionConfiguration(configuration)
        }

        state = .auction(controller: auction)
        
        Cacher.Main.interstitialStorage.beginIteration()

        // single-load callback: insert into cache + report refill outcome
        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }

            let ad = BidContainer(bid: bid)

            let result = Cacher.Main.interstitialStorage.insert(ad, sticky: self.isFirstLoad)
            if result.isInserted {
                self.adRevenueObserver.observe(bid)
            } else {
                Cacher.Fallback.interstitialStorage.insert(ad)
            }

            if self.isFirstLoad {
                let controller = ImpressionControllerType(bid: bid)
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

                DispatchQueue.main.async { [weak self] in
                    guard let self else { 
                        return 
                    }
                    
                    self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                }
            }

            self.isFirstLoad = false
        }

        auction.load { [unowned observer, weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                // If your auction can end "success" without any bids delivered via `singleLoadCompletion`,
                // you should call `.noFill` here. Otherwise, keep as-is.
                break

            case .failure(let error):
                // fetch from fallback cache
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let ad = Cacher.Fallback.interstitialStorage.peek() as? BidContainer, ad.price >= self.pricefloor {
                        // Update auctionInfo: set WIN status for the cached ad
                        if let index = self.auctionInfo.adUnits?.firstIndex(where: { $0.demandId == ad.bid.adUnit.demandId && $0.uid == ad.bid.adUnit.uid }),
                           let adUnitInfo = self.auctionInfo.adUnits?[index] as? DefaultAdUnitInfo {
                            adUnitInfo.status = DemandMediationStatus.win.stringValue
                        } else {
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
                        }
                        let controller = ImpressionControllerType(bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>)
                        controller.delegate = self
                        self.state = .ready(controller: controller)
                        
                        self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                    } else {
                        self.state = .idle
                        self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                    }
                }
            }
            
            self.sendAuctionReport(observer.report)

            self.auction = nil
        }

        self.auction = auction
    }
}
