//
//  MintegralBiddingAdViewDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MTGSDKBidding
import MTGSDKBanner


extension MTGBannerAdView: DemandAd {
    public var id: String { unitId }
}


final class MintegralBiddingAdViewDemandProvider: MintegralBiddingBaseDemandProvider<MTGBannerAdView> {
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

    override func load(
        payload: MintegralBiddingResponse,
        adUnitExtras: MintegralAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.adView = MTGBannerAdView(
                bannerAdViewWith: adType,
                placementId: adUnitExtras.placementId,
                unitId: adUnitExtras.unitId,
                rootViewController: self.rootViewController
            )

            self.adView.autoRefreshTime = 0
            self.adView.delegate = self
            self.adView.loadBannerAd(withBidToken: payload.payload)
        }
    }
}


extension MintegralBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: MTGBannerAdView) -> Bidon.AdViewContainer? {
        return ad
    }

    func didTrackImpression(for ad: MTGBannerAdView) {}
}


extension MintegralBiddingAdViewDemandProvider: MTGBannerAdViewDelegate {
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


extension MTGBannerAdView: Bidon.AdViewContainer {
    public var isAdaptive: Bool { true }
}


extension Bidon.BannerFormat {
    var mtg: MTGBannerSizeType {
        switch self {
        case .banner:
            return .standardBannerType320x50
        case .mrec:
            return .mediumRectangularBanner300x250
        case .adaptive, .leaderboard:
            return .smartBannerType
        }
    }
}
