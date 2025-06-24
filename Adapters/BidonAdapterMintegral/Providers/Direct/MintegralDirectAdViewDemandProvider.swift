//
//  MintegralDirectAdViewDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Евгения Григорович on 22/08/2024.
//

import Foundation
import Bidon
import MTGSDKBanner

final class MintegralDirectAdViewDemandProvider: MintegralDirectBaseDemandProvider<MTGBannerAdView> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    private let adType: MTGBannerSizeType
    private var response: Bidon.DemandProviderResponse?

    init(
        context: AdViewContext
    ) {
        self.rootViewController = context.rootViewController
        self.adType = context.format.mtg
        super.init()
    }

    var adView: MTGBannerAdView!

    override func load(pricefloor: Price, adUnitExtras: MintegralAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            adView = MTGBannerAdView(
                bannerAdViewWith: adType,
                placementId: adUnitExtras.placementId,
                unitId: adUnitExtras.unitId,
                rootViewController: self.rootViewController
            )

            adView.autoRefreshTime = 0
            adView.delegate = self
            adView.loadBannerAd()
        }
    }
}


extension MintegralDirectAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: MTGBannerAdView) -> Bidon.AdViewContainer? {
        return ad
    }

    func didTrackImpression(for ad: MTGBannerAdView) {}
}


extension MintegralDirectAdViewDemandProvider: MTGBannerAdViewDelegate {
    func adViewLoadSuccess(_ adView: MTGBannerAdView!) {
        response?(.success(adView))
        response = nil
    }

    func adViewLoadFailedWithError(_ error: Error!, adView: MTGBannerAdView!) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func adViewWillLogImpression(_ adView: MTGBannerAdView!) {
        revenueDelegate?.provider(self, didLogImpression: adView)
    }

    func adViewDidClicked(_ adView: MTGBannerAdView!) {
        delegate?.providerDidClick(self)
    }

    func adViewWillLeaveApplication(_ adView: MTGBannerAdView!) {
        adViewDelegate?.providerWillLeaveApplication(self, adView: adView)
    }

    func adViewWillOpenFullScreen(_ adView: MTGBannerAdView!) {
        adViewDelegate?.providerWillPresentModalView(self, adView: adView)

    }

    func adViewCloseFullScreen(_ adView: MTGBannerAdView!) {
        adViewDelegate?.providerDidDismissModalView(self, adView: adView)
    }

    func adViewClosed(_ adView: MTGBannerAdView!) {
        delegate?.providerDidHide(self)
    }
}
