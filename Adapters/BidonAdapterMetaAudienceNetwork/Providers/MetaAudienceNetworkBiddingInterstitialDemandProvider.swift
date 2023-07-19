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
    
    public var networkName: String {
        return MetaAudienceNetworkDemandSourceAdapter.identifier
    }
    
    public var dsp: String? {
        return nil
    }
}


final class MetaAudienceNetworkBiddingInterstitialDemandProvider: MetaAudienceNetworkBiddingBaseDemandProvider<FBInterstitialAd> {
    private lazy var interstitial: FBInterstitialAd = {
        let interstitial = FBInterstitialAd(placementID: "place")
        interstitial.delegate = self
        return interstitial
    }()
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        interstitial.load(withBidPayload: payload)
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
        response?(.failure(.noFill))
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
