//
//  GoogleMobileAdsBannerDemandProvider.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 08.07.2022.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit


final class GoogleMobileAdsBannerDemandProvider: GoogleMobileAdsBaseDemandProvider<GoogleMobileAds.BannerView> {
    private weak var rootViewController: UIViewController?

    private let adSize: GoogleMobileAds.AdSize
    private var banner: GoogleMobileAds.BannerView?

    weak var adViewDelegate: DemandProviderAdViewDelegate?

    init(
        parameters: GoogleMobileAdsParameters,
        context: AdViewContext
    ) {
        self.adSize = context.adSize
        self.rootViewController = context.rootViewController
        super.init(parameters: parameters)
    }

    override func loadAd(_ request: GoogleMobileAds.Request, adUnitId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let banner = GoogleMobileAds.BannerView(adSize: adSize)

            banner.delegate = self
            banner.adUnitID = adUnitId
            banner.rootViewController = rootViewController

            setupAdRevenueHandler(adObject: banner)

            banner.load(request)

            self.banner = banner
        }
    }
}


extension GoogleMobileAdsBannerDemandProvider: AdViewDemandProvider {
    func container(for ad: GoogleMobileAds.BannerView) -> AdViewContainer? {
        return ad
    }

    func didTrackImpression(for ad: GoogleMobileAds.BannerView) {}
}


extension GoogleMobileAdsBannerDemandProvider: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        handleDidLoad(adObject: bannerView)
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
        handleDidFailToLoad(.noFill(error.localizedDescription))
    }

    func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
        adViewDelegate?.providerWillPresentModalView(self, adView: bannerView)
    }

    func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
        adViewDelegate?.providerDidDismissModalView(self, adView: bannerView)
    }

    func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
        delegate?.providerDidClick(self)
    }
}


extension AdViewContext {
    var adSize: AdSize {
        switch format {
        case .mrec: return AdSizeMediumRectangle
        case .banner: return AdSizeBanner
        case .leaderboard: return AdSizeLeaderboard
        default: return currentOrientationAnchoredAdaptiveBanner(width: width)
        }
    }

    private var width: CGFloat {
        guard let window = UIApplication.shared.bd.window else { return 0 }
        if #available(iOS 11, *) {
            return window.bounds.inset(by: window.safeAreaInsets).width
        } else {
            return window.bounds.width
        }
    }
}


extension GoogleMobileAds.BannerView: AdViewContainer {
    public var isAdaptive: Bool { return true }
}
