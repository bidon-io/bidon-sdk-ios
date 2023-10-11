//
//  AmazonInterstitialBiddingDemandProvider.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 28.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


final class AmazonBiddingInterstitialDemandProvider: AmazonBiddingDemandProvider<DTBAdInterstitialDispatcher> {
    private lazy var dispatcher = DTBAdInterstitialDispatcher(delegate: self)
    private var response: DemandProviderResponse?
    
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override func fill(
        _ data: DTBAdResponse,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        dispatcher.fetchAd(withParameters: data.mediationHints())
    }
}


extension AmazonBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: DTBAdInterstitialDispatcher, from viewController: UIViewController) {
        ad.show(from: viewController)
    }
}


extension AmazonBiddingInterstitialDemandProvider: RewardedAdDemandProvider {}


extension AmazonBiddingInterstitialDemandProvider: DTBAdInterstitialDispatcherDelegate {
    func interstitialDidLoad(_ interstitial: DTBAdInterstitialDispatcher?) {
        guard let interstitial = interstitial else { return }
        response?(.success(interstitial))
        response = nil
    }
    
    func interstitial(
        _ interstitial: DTBAdInterstitialDispatcher?,
        didFailToLoadAdWith errorCode: DTBAdErrorCode
    ) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func interstitialWillPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        delegate?.providerWillPresent(self)
    }
    
    func interstitialDidDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
        delegate?.providerDidHide(self)
    }

    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func impressionFired() {
        revenueDelegate?.provider(self, didLogImpression: dispatcher)
    }
    
    // noop
    func interstitialDidPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func interstitialWillDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func interstitialWillLeaveApplication(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func show(fromRootViewController controller: UIViewController) {}
}
