//
//  MetaAudienceNetworkBiddingAdViewDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


extension FBAdView: DemandAd {
    public var id: String {
        return placementID
    }
    
    public var networkName: String {
        return MetaAudienceNetworkDemandSourceAdapter.identifier
    }
    
    public var dsp: String? {
        return nil
    }
}


final class MetaAudienceNetworkBiddingAdViewDemandProvider: MetaAudienceNetworkBiddingBaseDemandProvider<FBAdView> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    private let format: BannerFormat
    private weak var rootViewController: UIViewController?
    
    private var response: DemandProviderResponse?
    
    private lazy var banner: FBAdView = {
        let banner = FBAdView(
            placementID: "place",
            adSize: format.fbAdSize,
            rootViewController: rootViewController
        )
        
        banner.delegate = self
        return banner
    }()
    
    init(context: AdViewContext) {
        self.format = context.format
        self.rootViewController = context.rootViewController
        super.init()
    }
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        banner.loadAd(withBidPayload: payload)
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
        response?(.failure(.noFill))
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
