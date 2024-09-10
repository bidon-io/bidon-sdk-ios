//
//  MetaAudienceNetworkBiddingAdViewDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


extension FBAdView: DemandAd {
    public var id: String {
        return placementID
    }
}


final class MetaAudienceNetworkBiddingAdViewDemandProvider: MetaAudienceNetworkBiddingBaseDemandProvider<FBAdView> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    private let format: BannerFormat
    private weak var rootViewController: UIViewController?
    
    private var response: DemandProviderResponse?
    
    private var banner: FBAdView?
    
    init(context: AdViewContext) {
        self.format = context.format
        self.rootViewController = context.rootViewController
        super.init()
    }
    
    override func load(
        payload: MetaAudienceNetworkBiddingPayload,
        adUnitExtras: MetaAudienceNetworkAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let banner = FBAdView(
            placementID: adUnitExtras.placementId,
            adSize: format.fbAdSize,
            rootViewController: rootViewController
        )
        banner.delegate = self
            
        self.banner = banner
        self.response = response
        
        banner.loadAd(withBidPayload: payload.payload)
    }
}


extension MetaAudienceNetworkBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: FBAdView) -> AdViewContainer? {
        return ad.isAdValid ? ad : nil
    }
    
    func didTrackImpression(for ad: FBAdView) {}
}


extension MetaAudienceNetworkBiddingAdViewDemandProvider: FBAdViewDelegate {
    func adViewDidLoad(_ adView: FBAdView) {
        response?(.success(adView))
        response = nil
    }
    
    func adView(_ adView: FBAdView, didFailWithError error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func adViewWillLogImpression(_ adView: FBAdView) {
        revenueDelegate?.provider(self, didLogImpression: adView)
        delegate?.providerWillPresent(self)
    }
    
    func adViewDidClick(_ adView: FBAdView) {
        delegate?.providerDidClick(self)
    }
}


extension BannerFormat {
    var fbAdSize: FBAdSize {
        switch self {
        case .banner:
            return kFBAdSizeHeight50Banner
        case .leaderboard:
            return kFBAdSizeHeight90Banner
        case .mrec:
            return kFBAdSizeHeight250Rectangle
        case .adaptive:
            return kFBAdSizeHeight250Rectangle
        }
    }
}


extension FBAdView: AdViewContainer {
    public var isAdaptive: Bool {
        return true
    }
}
