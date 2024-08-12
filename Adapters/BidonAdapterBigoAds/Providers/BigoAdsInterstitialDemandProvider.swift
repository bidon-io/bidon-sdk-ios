//
//  BigoAdsInterstitialDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsInterstitialDemandProvider: BigoAdsBaseDemandProvider<BigoInterstitialAd> {
    private lazy var loader = BigoInterstitialAdLoader(interstitialAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    override func load(
        payload: BigoAdsBiddingPayload,
        adUnitExtras: BigoAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        let request = BigoInterstitialAdRequest(slotId: adUnitExtras.slotId)
        request.setServerBidPayload(payload.payload)
        
        loader.loadAd(request)
    }
    
    override func load(pricefloor: Price, adUnitExtras: BigoAdsAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response
        
        let request = BigoInterstitialAdRequest(slotId: adUnitExtras.slotId)
        
        loader.loadAd(request)
    }
}


extension BigoAdsInterstitialDemandProvider: InterstitialDemandProvider {
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


extension BigoAdsInterstitialDemandProvider: BigoInterstitialAdLoaderDelegate {
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
