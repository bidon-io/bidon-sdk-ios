//
//  ZhenyaSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

enum ZhenyaSandbox {
    private static var bannerManagers: [String: BannerAdManager] = [:]
    
    static func buildBannerManager(
        placement: String,
        adRevenueObserver: AdRevenueObserver
    ) -> BannerAdManager {
        
        if let manager = bannerManagers[placement] {
            return manager
        }
        
        let manager = ZhenyaBannerAdManager(
            placement: placement,
            adRevenueObserver: adRevenueObserver
        )
        
        bannerManagers[placement] = manager
        return manager
    }
}

final class ZhenyaBannerAdManager: BannerAdManager {
    typealias ZhenyaAuctionControllerType = ZhenyaAuctionController<BannerAdTypeContext>

    var isFirstLoad: Bool = true
    var auction: ZhenyaAuctionControllerType?
    
    override func prepareForReuse() {
        defer {
            super.prepareForReuse()
        }
        if Cacher.Main.bannerStorage.peek() != nil {
            Cacher.Main.bannerStorage.popFirst()
            return
        }
        if Cacher.Fallback.bannerStorage.peek() != nil {
            Cacher.Fallback.bannerStorage.popFirst()
            return
        }
    }
    
    override func loadAd(pricefloor: Price, viewContext: AdViewContext, auctionKey: String?) {
        auctionInfo = DefaultAuctionInfo()
        Logger.debug("[ZhenyaCache] [Banner] loadAd | floor: \(pricefloor) | key: \(auctionKey ?? "default") | cached: \(Cacher.Main.bannerStorage.peek() != nil)")
        
        // If cache has a bid container that already meets the floor — use it.
        if let ad = Cacher.Main.bannerStorage.peek() as? BidContainer, ad.price >= pricefloor {
            let controller = AdViewImpression(
                bid: (ad.bid as! BidModel<DemandProviderWrapper<any AdViewDemandProvider>>).unwrapped(),
                format: BannerAdTypeContext(viewContext: viewContext).format
            )
            
            self.state = .ready(impression: controller)
            
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

        super.loadAd(pricefloor: pricefloor, viewContext: viewContext, auctionKey: auctionKey)
    }
    
    override func performAuction(
        auctionInfo: AuctionInfo,
        tokens: [BiddingDemandToken],
        viewContext: AdViewContext
    ) {
        if isCanceled {
            return
        }
        Logger.verbose("Banner ad manager will start auction: \(auctionInfo)")
        
        Logger.debug("[ZhenyaCache] [Banner] performAuction")
        
        isFirstLoad = true

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

        let auction = ZhenyaAuctionControllerType { (builder: AdViewConcurrentAuctionControllerBuilder) in
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
        
        Cacher.Main.bannerStorage.beginIteration()
        
        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }

            let ad = BidContainer(bid: bid)

            let result = Cacher.Main.bannerStorage.insert(ad, sticky: self.isFirstLoad)
            if result.isInserted {
                self.adRevenueObserver.observe(bid)
            } else {
                Cacher.Fallback.bannerStorage.insert(ad)
            }

            if self.isFirstLoad {
                adRevenueObserver.observe(bid)
                let controller = AdViewImpression(
                    bid: bid.unwrapped(),
                    format: context.format
                )
                self.state = .ready(impression: controller)
                
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
            guard let self = self else { return }

            self.sendAuctionReport(observer.report, viewContext: viewContext)

            var allDemands = observer.report.round.demands
            if let biddingDemands = observer.report.round.bidding?.demands {
                allDemands += biddingDemands
            }
            self.auctionInfo.adUnits = allDemands.compactMap({ DefaultAdUnitInfo($0) })

            switch result {
            case .success:
                break

            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let ad = Cacher.Fallback.bannerStorage.peek() as? BidContainer {
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
                        let controller = AdViewImpression(
                            bid: (ad.bid as! BidModel<DemandProviderWrapper<any AdViewDemandProvider>>).unwrapped(),
                            format: context.format
                        )
                        self.state = .ready(impression: controller)

                        self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                    } else {
                        self.state = .idle
                        self.delegate?.adManager(self, didFailToLoad: error, auctionInfo: self.auctionInfo)
                    }
                }
            }

            self.auction = nil
        }
        
        self.auction = auction
    }
}
