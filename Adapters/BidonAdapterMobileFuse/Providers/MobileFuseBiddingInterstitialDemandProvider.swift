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
    private lazy var interstitial: MFInterstitialAd? = {
#warning("Placement is missing")
        let interstitial = MFInterstitialAd(placementId: "placement")
        interstitial?.register(self)
        return interstitial
    }()
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        if let interstitial = interstitial {
            self.response = response
            interstitial.load(withBiddingResponseToken: payload)
        } else {
            response(.failure(.unscpecifiedException))
        }
    }
}


extension MobileFuseBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: MFInterstitialAd, from viewController: UIViewController) {
        ad.show()
    }
}
