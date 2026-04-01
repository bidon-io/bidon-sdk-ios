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

    var isFirstFill: Bool = true
    var auction: AdCacheAuctionControllerType?
    var cacheKey: String = "default"

    lazy var storage = Cacher.storage(for: context.adType, auctionKey: cacheKey)

    override var isReady: Bool {
        return storage.peekMain() != nil || storage.peekFallback() != nil
    }

    // MARK: - loadAd (spec §7)

    override func loadAd(pricefloor: Price, auctionKey: String?) {
        // 1. Main has ad → instant serve (no pricefloor check per spec §5)
        if let ad = storage.peekMain() as? BidContainer {
            Logger.debug("[AdCache][\(cacheKey)] loadAd | served from cache")
            let controller = ImpressionControllerType(
                bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>
            )
            controller.delegate = self
            self.state = .ready(controller: controller)
            auctionInfo = DefaultAuctionInfo()
            (auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)
            self.delegate?.adManager(self, didLoad: ad, auctionInfo: auctionInfo)
            return
        }

        // 2. Main empty → auction
        Logger.debug("[AdCache][\(cacheKey)] loadAd | floor: \(pricefloor) | main empty → auction")
        auctionInfo = DefaultAuctionInfo()
        super.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }

    // MARK: - show (spec §8)

    override func show(from rootViewController: UIViewController) {
        auction?.cancel()
        auction = nil

        switch state {
        case .ready:
            guard let ad = storage.popFirst() as? BidContainer else { return }

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

    // MARK: - Fallback on request failure (spec §7 step 3)

    override func handlePerformAuctionRequestFailed(error: any Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let ad = self.storage.peekFallback() as? BidContainer {
                Logger.debug("[AdCache][\(self.cacheKey)] Request failed → served from fallback")
                self.auctionInfo = DefaultAuctionInfo()
                (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)
                let controller = ImpressionControllerType(
                    bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>
                )
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

    // MARK: - performAuction (spec §7 step 4)

    override func performAuction(
        _ auctionInfo: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>.AuctionInfo,
        tokens: [BiddingDemandToken]
    ) {
        isFirstFill = true

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

        // Pre-filter (spec §11)
        auction.shouldCancelBeforeNextAdUnit = { [weak self] ecpm in
            self?.storage.shouldStop(ecpm: ecpm) ?? true
        }

        // Route each filled bid (spec §7 pseudocode)
        auction.singleLoadCompletion = { [weak self] bid in
            guard let self else { return }

            let ad = BidContainer(bid: bid)
            let result = self.storage.route(ad, sticky: self.isFirstFill)

            if result != .rejected {
                if self.isFirstFill {
                    observer.log(WinBidAuctionEvent(bid: bid))
                } else {
                    observer.log(CachedBidAuctionEvent(bid: bid))
                }
            }

            if result == .insertedMain {
                self.adRevenueObserver.observe(bid)
            }

            if self.isFirstFill && result != .rejected {
                let controller = ImpressionControllerType(bid: bid)
                controller.delegate = self
                self.state = .ready(controller: controller)

                (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.adManager(self, didLoad: ad, auctionInfo: self.auctionInfo)
                }
            }

            self.isFirstFill = false
        }

        // Auction completion
        auction.load { [unowned observer, weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                Logger.debug("[AdCache][\(self.cacheKey)] Auction finished | success")

            case .failure(let error):
                Logger.debug("[AdCache][\(self.cacheKey)] Auction finished | failure: \(error.localizedDescription)")
                // No-fill → try Fallback (spec §7 step 4)
                // Skip if show() already happened (state is .impression)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard case .auction = self.state else { return }
                    if let ad = self.storage.peekFallback() as? BidContainer {
                        Logger.debug("[AdCache][\(self.cacheKey)] No-fill → served from fallback")
                        (self.auctionInfo as? DefaultAuctionInfo)?.appendWinReport(for: ad)
                        let controller = ImpressionControllerType(
                            bid: ad.bid as! BidModel<AdTypeContextType.DemandProviderType>
                        )
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
