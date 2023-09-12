//
//  InMobiInterstitialDemandProvider.swift
//  BidonAdapterInMobi
//
//  Created by Stas Kochkin on 11.09.2023.
//

import Foundation
import UIKit
import Bidon
import InMobiSDK


extension IMInterstitial: InMobiAd {}


final class InMobiInterstitialDemandProvider: NSObject, DirectDemandProvider {
    typealias DemandAdType = InMobiDemandAd<IMInterstitial>
    
    weak var delegate: DemandProviderDelegate?
    weak var rewardDelegate: DemandProviderRewardDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    private var response: DemandProviderResponse?
    
    private var ad: DemandAdType?
    
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        guard let placement = Int64(adUnitId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        
        let interstitial = IMInterstitial(placementId: placement)
        interstitial.delegate = self
        interstitial.load()

        self.response = response
        self.ad = DemandAdType(ad: interstitial)
    }
    
    func notify(
        ad: DemandAdType,
        event: AuctionEvent
    ) {
        switch event {
        case .lose:
            ad.ad.cancel()
        default:
            break
        }
    }
}


extension InMobiInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: DemandAdType, from viewController: UIViewController) {
        guard ad.ad.isReady() else {
            delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
            return
        }
        
        ad.ad.show(from: viewController)
    }
}


extension InMobiInterstitialDemandProvider: RewardedAdDemandProvider {}


extension InMobiInterstitialDemandProvider: IMInterstitialDelegate {
    func interstitialDidFinishLoading(_ interstitial: IMInterstitial) {
        response?(.success(DemandAdType(ad: interstitial)))
        response = nil
    }
    
    func interstitial(
        _ interstitial: IMInterstitial,
        didFailToReceiveWithError error: Error
    ) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func interstitial(
        _ interstitial: IMInterstitial,
        didFailToLoadWithError error: IMRequestStatus
    ) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func interstitial(_ interstitial: IMInterstitial, didFailToPresentWithError error: IMRequestStatus) {
        delegate?.provider(
            self,
            didFailToDisplayAd: DemandAdType(ad: interstitial),
            error: .cancelled
        )
    }
    
    func interstitialDidPresent(_ interstitial: IMInterstitial) {
        delegate?.providerWillPresent(self)
    }
    
    func interstitial(_ interstitial: IMInterstitial, didInteractWithParams params: [String : Any]?) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialDidDismiss(_ interstitial: IMInterstitial) {
        delegate?.providerDidHide(self)
    }
    
    func interstitialAdImpressed(_ interstitial: IMInterstitial) {
        revenueDelegate?.provider(self, didLogImpression: DemandAdType(ad: interstitial))
    }
    
    func interstitial(_ interstitial: IMInterstitial, rewardActionCompletedWithRewards rewards: [String : Any]) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
