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


final class GoogleAdManagerDirectAdViewProvider: GoogleAdManagerBaseDemandProvider<GoogleMobileAds.BannerView> {
    private weak var rootViewController: UIViewController?
    
    private let adSize: GoogleMobileAds.AdSize
    private var banner: GoogleMobileAds.BannerView?
    private var container: GoogleMobileAdsBannerContainerView
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    init(
        parameters: GoogleAdManagerParameters,
        context: AdViewContext
    ) {
        let frame = CGRect(origin: .zero, size: context.format.preferredSize)
        self.adSize = context.adSize
        self.rootViewController = context.rootViewController
        self.container = context.format == .adaptive ?
        GoogleMobileAdsAdaptiveBannerContainerView(frame: frame, adSize: context.adSize) :
        GoogleMobileAdsFixedBannerContainerView(frame: frame, adSize: context.adSize)
        
        super.init(parameters: parameters)
    }
    
    override func loadAd(_ request: GoogleMobileAds.Request, adUnitId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let banner = GoogleMobileAds.BannerView(adSize: adSize)
            
            banner.delegate = self
            banner.adUnitID = adUnitId
            banner.isAutoloadEnabled = false
            banner.rootViewController = self.rootViewController
            
            self.setupAdRevenueHandler(adObject: banner)
            
            banner.translatesAutoresizingMaskIntoConstraints = false
            
            self.container.layout(banner)
            
            banner.load(request)
            
            self.banner = banner
        }
    }
}


extension GoogleAdManagerDirectAdViewProvider: AdViewDemandProvider {
    func container(for ad: GoogleMobileAds.BannerView) -> AdViewContainer? {
        return self.container
    }
    
    func didTrackImpression(for ad: GoogleMobileAds.BannerView) {
        ad.unhideSubviews()
    }
}


extension GoogleAdManagerDirectAdViewProvider: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        handleDidLoad(adObject: bannerView)
    }
    
    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
        handleDidFailToLoad(.noFill(error.localizedDescription))
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
        adViewDelegate?.providerWillPresentModalView(self, adView: container)
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
        adViewDelegate?.providerDidDismissModalView(self, adView: container)
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


extension GoogleMobileAds.BannerView {
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
