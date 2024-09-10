//
//  MetaAudienceNetworkBiddingInterstitialDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


extension FBInterstitialAd: DemandAd {
    public var id: String {
        return placementID
    }
}


final class MetaAudienceNetworkBiddingInterstitialDemandProvider: MetaAudienceNetworkBiddingBaseDemandProvider<FBInterstitialAd> {
    private var interstitial: FBInterstitialAd!
    
    private var response: DemandProviderResponse?
    
    override func load(
        payload: MetaAudienceNetworkBiddingPayload,
        adUnitExtras: MetaAudienceNetworkAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let interstitial = FBInterstitialAd(placementID: adUnitExtras.placementId)
        interstitial.delegate = self
        
        self.interstitial = interstitial
        self.response = response
        
        interstitial.load(withBidPayload: payload.payload)
    }
}


extension MetaAudienceNetworkBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: FBInterstitialAd,
        from viewController: UIViewController
    ) {
        if ad.isAdValid {
            ad.show(fromRootViewController: viewController)
        } else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        }
    }
}


extension MetaAudienceNetworkBiddingInterstitialDemandProvider: FBInterstitialAdDelegate {
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        response?(.success(interstitialAd))
        response = nil
    }
    
    func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        revenueDelegate?.provider(self, didLogImpression: interstitialAd)
        delegate?.providerWillPresent(self)
    }
    
    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        delegate?.providerDidHide(self)
    }
}
