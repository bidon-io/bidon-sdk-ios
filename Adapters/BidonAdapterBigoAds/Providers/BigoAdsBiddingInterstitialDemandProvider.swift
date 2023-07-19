//
//  BigoAdsBiddingInterstitialDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsBiddingInterstitialDemandProvider: BigoAdsBiddingBaseDemandProvider<BigoInterstitialAd> {
    private lazy var loader = BigoInterstitialAdLoader(interstitialAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
#warning("Slot ID")
        let request = BigoInterstitialAdRequest(slotId: "some slot id")
        request.setServerBidPayload(payload)
        
        loader.loadAd(request)
    }
}


extension BigoAdsBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: BigoInterstitialAd, from viewController: UIViewController) {
        if ad.isExpired() {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        } else {
            ad.show(viewController)
        }
    }
}


extension BigoAdsBiddingInterstitialDemandProvider: BigoInterstitialAdLoaderDelegate {
    func onInterstitialAdLoaded(_ ad: BigoInterstitialAd) {
        ad.setAdInteractionDelegate(self)
        response?(.success(ad))
        response = nil
    }
    
    func onInterstitialAdLoadError(_ error: BigoAdError) {
        response?(.failure(MediationError(error: error)))
        response = nil
    }
}
