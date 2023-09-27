//
//  MobileFuseBiddingInterstitialDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK



final class MobileFuseBiddingInterstitialDemandProvider: MobileFuseBiddingBaseDemandProvider<MFInterstitialAd> {
    private var interstitial: MFInterstitialAd?
    
    override func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        if let interstitial = MFInterstitialAd(placementId: data.placementId) {
            self.response = response
            self.interstitial = interstitial
            
            interstitial.register(self)
            interstitial.load(withBiddingResponseToken: data.signal)
        } else {
            response(.failure(.unscpecifiedException))
        }
    }
}


extension MobileFuseBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: MFInterstitialAd, from viewController: UIViewController) {
        viewController.view.addSubview(ad)
        ad.show()
    }
}
