//
//  MintegralDirectInterstitialDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Евгения Григорович on 22/08/2024.
//

import Foundation
import Bidon
import MTGSDK
import MTGSDKNewInterstitial


extension MTGNewInterstitialAdManager: DemandAd {
    public var id: String { currentUnitId }
}


final class MintegralDirectInterstitialDemandProvider: MintegralDirectBaseDemandProvider<MTGNewInterstitialAdManager> {
    private var response: Bidon.DemandProviderResponse?

    private var interstitial: MTGNewInterstitialAdManager?

    override func load(pricefloor: Price, adUnitExtras: MintegralAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response

        interstitial = MTGNewInterstitialAdManager(
            placementId: adUnitExtras.placementId,
            unitId: adUnitExtras.unitId,
            delegate: self
        )
        interstitial?.loadAd()
    }
}


extension MintegralDirectInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: MTGNewInterstitialAdManager, from viewController: UIViewController) {
        if interstitial?.isAdReady() == true {
            interstitial?.show(from: viewController)
        } else {
            delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
        }
    }
}


extension MintegralDirectInterstitialDemandProvider: MTGNewInterstitialAdDelegate {
    func newInterstitialAdLoadSuccess(_ adManager: MTGNewInterstitialAdManager) {
        response?(.success(adManager))
        response = nil
    }

    func newInterstitialAdLoadFail(_ error: Error, adManager: MTGNewInterstitialAdManager) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func newInterstitialAdShowSuccess(_ adManager: MTGNewInterstitialAdManager) {
        delegate?.providerWillPresent(self)

        revenueDelegate?.provider(self, didLogImpression: adManager)
    }

    func newInterstitialAdShowFail(_ error: Error, adManager: MTGNewInterstitialAdManager) {
        delegate?.provider(self, didFailToDisplayAd: adManager, error: .generic(error: error))
    }

    func newInterstitialAdClicked(_ adManager: MTGNewInterstitialAdManager) {
        delegate?.providerDidClick(self)
    }

    func newInterstitialAdDismissed(withConverted converted: Bool, adManager: MTGNewInterstitialAdManager) {
        delegate?.providerDidHide(self)
    }
}
