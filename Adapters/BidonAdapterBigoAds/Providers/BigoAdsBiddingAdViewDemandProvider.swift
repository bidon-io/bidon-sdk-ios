//
//  BigoAdsBiddingAdViewDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsBiddingAdViewDemandProvider: BigoAdsBiddingBaseDemandProvider<BigoBannerAd> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    private lazy var loader = BigoBannerAdLoader(bannerAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    private let format: BannerFormat
    
    init(context: AdViewContext) {
        self.format = context.format
        super.init()
    }
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
#warning("Slot ID")
        let size = BigoAdSize.banner()
        let request = BigoBannerAdRequest(
            slotId: "some slot id",
            adSizes: [format.bigoAdSize]
        )
        request.setServerBidPayload(payload)
        
        loader.loadAd(request)
    }
    
    override func onAdOpened(_ ad: BigoAd) {
//        adViewDelegate?.providerWillPresentModalView(self, adView: <#T##AdViewContainer#>)
    }
    
    override func onAdClosed(_ ad: BigoAd) {
//        adViewDelegate?.providerDidDismissModalView(self, adView: <#T##AdViewContainer#>)
    }
}


extension BigoAdsBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BigoBannerAd) -> AdViewContainer? {
        return nil // ad.adView()
    }
    
    func didTrackImpression(for ad: BigoBannerAd) {}
}


extension BigoAdsBiddingAdViewDemandProvider: BigoBannerAdLoaderDelegate {
    func onBannerAdLoaded(_ ad: BigoBannerAd) {
        ad.setAdInteractionDelegate(self)
        
        response?(.success(ad))
        response = nil
    }
    
    func onBannerAdLoadError(_ error: BigoAdError) {
        response?(.failure(MediationError(error: error)))
        response = nil
    }
}


extension BannerFormat {
    var bigoAdSize: BigoAdSize {
        switch self {
        case .banner:
            return .banner()
        case .leaderboard:
            return .large_BANNER()
        case .mrec:
            return .medium_RECTANGLE()
        case .adaptive:
            return .banner()
        }
    }
}
