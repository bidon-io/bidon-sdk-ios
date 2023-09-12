//
//  UnityAdsBannerDemandProvider.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 02.03.2023.
//

import Foundation
import Bidon
import UnityAds
import UIKit


final class UnityAdsBannerDemandProvider: NSObject, DirectDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    private let size: CGSize
    
    private var banner: UADSBannerView?
    private var response: DemandProviderResponse?
        
    init(context: AdViewContext) {
        self.size = context.size
        super.init()
    }
    
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        let banner = UADSBannerView(
            placementId: adUnitId,
            size: size
        )
        
        banner.delegate = self
        
        self.response = response
        self.banner = banner
        
        banner.load()
    }
    
    func notify(ad: UADSBannerView, event: Bidon.AuctionEvent) {}
}


extension UnityAdsBannerDemandProvider: AdViewDemandProvider {
    func container(for ad: UADSBannerView) -> AdViewContainer? {
        return ad
    }
    
    func didTrackImpression(for ad: UADSBannerView) {
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}


extension UnityAdsBannerDemandProvider: UADSBannerViewDelegate {
    func bannerViewDidLoad(_ bannerView: UADSBannerView!) {
        guard let banner = banner, self.banner === banner else { return }
        
        response?(.success(banner))
        response = nil
    }
    
    func bannerViewDidError(_ bannerView: UADSBannerView!, error: UADSBannerError!) {
        guard self.banner === bannerView else { return }
        
        response?(.failure(MediationError(error)))
        response = nil
    }
    
    func bannerViewDidClick(_ bannerView: UADSBannerView!) {
        guard self.banner === bannerView else { return }
        
        delegate?.providerDidClick(self)
    }
    
    
    func bannerViewDidLeaveApplication(_ bannerView: UADSBannerView!) {
        guard let banner = banner, self.banner === bannerView else { return }
        
        adViewDelegate?.providerWillLeaveApplication(self, adView: banner)
    }
}


extension UADSBannerView: AdViewContainer {
    public var isAdaptive: Bool { false }
}
