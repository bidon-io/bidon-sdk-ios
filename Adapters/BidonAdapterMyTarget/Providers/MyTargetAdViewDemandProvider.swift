//
//  MyTargetAdViewDemandProvider.swift
//  BidonAdapterMyTarget
//
//  Created by Evgenia Gorbacheva on 05/08/2024.
//

import UIKit
import Bidon
import MyTargetSDK

final class MyTargetBannerDemandAd: DemandAd {
    var banner: MTRGAdView
    public var id: String { return String(banner.hash) }

    init(banner: MTRGAdView) {
        self.banner = banner
    }
}

final class MyTargetAdViewDemandProvider: MyTargetBaseDemandProvider<MyTargetBannerDemandAd> {
    private var banner: MTRGAdView?
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    let adSize: MTRGAdSize

    init(context: AdViewContext) {
        self.rootViewController = context.rootViewController
        self.adSize = context.format.myTargetAdSize

        super.init()
    }

    override func load(
        payload: MyTargetBiddingPayload,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let slotId = UInt(adUnitExtras.slotId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        self.response = response

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let banner = MTRGAdView(slotId: slotId)

            let customParams = banner.customParams
            customParams.setCustomParam(adUnitExtras.mediation, forKey: kMTRGCustomParamsMediationKey)

            banner.delegate = self
            banner.viewController = rootViewController
            banner.load(fromBid: payload.bidId)

            self.banner = banner
        }
    }

    override func load(
        pricefloor: Price,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let slotId = UInt(adUnitExtras.slotId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        self.response = response

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let banner = MTRGAdView(slotId: slotId)

            let customParams = banner.customParams
            customParams.setCustomParam(adUnitExtras.mediation, forKey: kMTRGCustomParamsMediationKey)

            banner.delegate = self
            banner.viewController = rootViewController
            banner.load()

            self.banner = banner
        }
    }
}

extension MyTargetAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: MyTargetBannerDemandAd) -> Bidon.AdViewContainer? {
        return ad.banner
    }

    func didTrackImpression(for ad: MyTargetBannerDemandAd) { }
}

extension MyTargetAdViewDemandProvider: MTRGAdViewDelegate {
    func onLoad(with adView: MTRGAdView) {
        let ad = MyTargetBannerDemandAd(banner: adView)
        response?(.success(ad))
        response = nil
    }

    func onLoadFailed(error: Error, adView: MTRGAdView) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func onAdShow(with adView: MTRGAdView) {
        delegate?.providerWillPresent(self)

        guard let banner else { return }
        let ad = MyTargetBannerDemandAd(banner: adView)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func onAdClick(with adView: MTRGAdView) {
        delegate?.providerDidClick(self)
    }
}

extension MTRGAdView: Bidon.AdViewContainer {
    public var isAdaptive: Bool { true }
}

private extension BannerFormat {
    var myTargetAdSize: MTRGAdSize {
        switch self {
        case .banner:
            return MTRGAdSize.adSize320x50()
        case .leaderboard:
            return MTRGAdSize.adSize728x90()
        case .mrec:
            return MTRGAdSize.adSize300x250()
        case .adaptive:
            return MTRGAdSize.forCurrentOrientation()
        }
    }
}
