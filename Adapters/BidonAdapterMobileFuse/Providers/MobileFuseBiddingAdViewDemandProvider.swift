//
//  MobileFuseBiddingAdViewDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK


final class MobileFuseBiddingAdViewDemandProvider: MobileFuseBiddingBaseDemandProvider<MFBannerAd> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    private let adSize: MFBannerAdSize
    
    private var adView: MFBannerAd?
    
    init(context: AdViewContext) {
        self.adSize = context.format.mobileFuse
        super.init()
    }
    
    override func load(
        payload: MobileFuseBiddingPayload,
        adUnitExtras: MobileFuseAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        if let banner = MFBannerAd(
            placementId: adUnitExtras.placementId,
            with: adSize
        ) {
            self.adView = banner
            self.response = response
            
            banner.register(self)
            banner.load(withBiddingResponseToken: payload.signal)
        } else {
            response(.failure(.unscpecifiedException("Mapping Error")))
        }
    }
    
    func onAdExpanded(_ ad: MFAd!) {
        guard let ad = ad as? MFBannerAd else { return }
        adViewDelegate?.providerWillPresentModalView(self, adView: ad)
    }
    
    func onAdCollapsed(_ ad: MFAd!) {
        guard let ad = ad as? MFBannerAd else { return }
        adViewDelegate?.providerDidDismissModalView(self, adView: ad)
    }
}


extension MobileFuseBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: MFBannerAd) -> AdViewContainer? {
        ad.show()
        return ad
    }
    
    func didTrackImpression(for ad: MFBannerAd) {}
}


extension MFBannerAd: AdViewContainer {
    public var isAdaptive: Bool { false }
}


extension Bidon.BannerFormat {
    var mobileFuse: MFBannerAdSize {
        switch self {
        case .banner:
            return .MOBILEFUSE_BANNER_SIZE_320x50
        case .leaderboard:
            return .MOBILEFUSE_BANNER_SIZE_728x90
        case .mrec:
            return .MOBILEFUSE_BANNER_SIZE_300x250
        case .adaptive:
            return .MOBILEFUSE_BANNER_SIZE_DEFAULT
        }
    }
}
