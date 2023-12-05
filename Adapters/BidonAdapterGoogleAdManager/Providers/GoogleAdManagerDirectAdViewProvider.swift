//
//  GoogleAdManagerDirectAdViewProvider.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit


final class GoogleAdManagerDirectAdViewProvider: GoogleAdManagerBaseDemandProvider<GAMBannerView> {
    private weak var rootViewController: UIViewController?
    
    private let adSize: GADAdSize
    private var banner: GAMBannerView?
    private var container: GoogleMobileAdsBannerContainerView
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    init(
        serverData: GoogleAdManagerDemandSourceAdapter.ServerData,
        context: AdViewContext
    ) {
        let frame = CGRect(origin: .zero, size: context.format.preferredSize)
        self.adSize = context.adSize
        self.rootViewController = context.rootViewController
        self.container = context.format == .adaptive ?
        GoogleMobileAdsAdaptiveBannerContainerView(frame: frame, adSize: context.adSize) :
        GoogleMobileAdsFixedBannerContainerView(frame: frame, adSize: context.adSize)
        
        super.init(serverData: serverData)
    }
    
    override func loadAd(_ request: GADRequest, adUnitId: String) {
        let banner = GAMBannerView(adSize: adSize)
        
        banner.delegate = self
        banner.adUnitID = adUnitId
        banner.isAutoloadEnabled = false
        banner.rootViewController = rootViewController
        
        setupAdRevenueHandler(adObject: banner)
        
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        container.layout(banner)
        
        banner.load(request)
        
        self.banner = banner
    }
}


extension GoogleAdManagerDirectAdViewProvider: AdViewDemandProvider {
    func container(for ad: GAMBannerView) -> AdViewContainer? {
        return self.container
    }
    
    func didTrackImpression(for ad: GAMBannerView) {
        ad.unhideSubviews()
    }
}


extension GoogleAdManagerDirectAdViewProvider: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        guard let bannerView = bannerView as? GAMBannerView else { return }
        handleDidLoad(adObject: bannerView)
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        handleDidFailToLoad(.noFill)
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        adViewDelegate?.providerWillPresentModalView(self, adView: container)
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        adViewDelegate?.providerDidDismissModalView(self, adView: container)
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


extension GADBannerView {
    func unhideSubviews() {
        recursiveSubviews
            .filter { $0.isHidden }
            .forEach { $0.isHidden = false }
    }
}


extension UIView {
    var recursiveSubviews:[UIView] {
        var recursiveSubviews:[UIView] = subviews
        subviews.forEach { recursiveSubviews += $0.recursiveSubviews }
        return recursiveSubviews
    }
}
