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


final class GoogleMobileAdsBannerDemandProvider: GoogleMobileAdsBaseDemandProvider<GADBannerView> {
    private weak var rootViewController: UIViewController?
    
    private let adSize: GADAdSize
    private var banner: GADBannerView?
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    init(
        serverData: GoogleMobileAdsDemandSourceAdapter.ServerData,
        context: AdViewContext
    ) {
        self.adSize = context.adSize
        self.rootViewController = context.rootViewController
        super.init(serverData: serverData)
    }

    override func loadAd(_ request: GADRequest, adUnitId: String) {
        let banner = GADBannerView(adSize: adSize)
                
        banner.delegate = self
        banner.adUnitID = adUnitId
        banner.rootViewController = rootViewController
        
        setupAdRevenueHandler(adObject: banner)
        
        banner.load(request)
        
        self.banner = banner
    }
}


extension GoogleMobileAdsBannerDemandProvider: AdViewDemandProvider {
    func container(for ad: GADBannerView) -> AdViewContainer? {
        return ad
    }
    
    func didTrackImpression(for ad: GADBannerView) {}
}


extension GoogleMobileAdsBannerDemandProvider: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        handleDidLoad(adObject: bannerView)
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        handleDidFailToLoad(.noFill)
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        adViewDelegate?.providerWillPresentModalView(self, adView: bannerView)
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        adViewDelegate?.providerDidDismissModalView(self, adView: bannerView)
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        delegate?.providerDidClick(self)
    }
}


extension AdViewContext {
    var adSize: GADAdSize {
        switch format {
        case .mrec: return GADAdSizeMediumRectangle
        case .banner: return GADAdSizeBanner
        case .leaderboard: return GADAdSizeLeaderboard
        default: return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
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


extension GADBannerView: AdViewContainer {
    public var isAdaptive: Bool { return true }
}
