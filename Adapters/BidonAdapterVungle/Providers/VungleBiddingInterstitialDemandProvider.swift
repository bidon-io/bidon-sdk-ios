//
//  VungleBiddingInterstitialDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation
import UIKit
import Bidon
import VungleAdsSDK



final class VungleBiddingInterstitialDemandProvider: VungleBiddingBaseDemandProvider<VungleInterstitial> {
    override func adObject(placement: String) -> VungleInterstitial {
        let interstitial = VungleInterstitial(placementId: placement)
        interstitial.delegate = self
        return interstitial
    }
}


extension VungleBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: VungleDemandAd<VungleInterstitial>,
        from viewController: UIViewController
    ) {
        if ad.adObject.canPlayAd() {
            ad.adObject.present(with: viewController)
        } else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        }
    }
}

extension VungleBiddingInterstitialDemandProvider: VungleInterstitialDelegate {
    func interstitialAdDidLoad(_ interstitial: VungleInterstitial) {
        guard demandAd.adObject === interstitial else { return }
        
        response?(.success(demandAd))
        response = nil
    }
    
    func interstitialAdDidFailToLoad(_ interstitial: VungleInterstitial, withError: NSError) {
        guard demandAd.adObject === interstitial else { return }

        response?(.failure(.noFill))
        response = nil
    }
    
    func interstitialAdDidFailToPresent(_ interstitial: VungleInterstitial, withError: NSError) {
        guard demandAd.adObject === interstitial else { return }

        delegate?.provider(
            self,
            didFailToDisplayAd: demandAd,
            error: .generic(error: withError)
        )
    }
    
    func interstitialAdWillPresent(_ interstitial: VungleInterstitial) {
        guard demandAd.adObject === interstitial else { return }

        delegate?.providerWillPresent(self)
    }
    
    func interstitialAdDidTrackImpression(_ interstitial: VungleInterstitial) {
        guard demandAd.adObject === interstitial else { return }

        revenueDelegate?.provider(self, didLogImpression: demandAd)
    }
    
    func interstitialAdDidClick(_ interstitial: VungleInterstitial) {
        guard demandAd.adObject === interstitial else { return }

        delegate?.providerDidClick(self)
    }
    
    func interstitialAdDidClose(_ interstitial: VungleInterstitial) {
        guard demandAd.adObject === interstitial else { return }

        delegate?.providerDidHide(self)
    }
}
