//
//  MintegralBiddingInterstitialDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Stas Kochkin on 05.07.2023.
//

import Foundation
import Bidon
import MTGSDK
import MTGSDKBidding
import MTGSDKNewInterstitial


extension MTGNewInterstitialBidAdManager: DemandAd {
    public var id: String { currentUnitId }
    public var networkName: String { MintegralDemandSourceAdapter.identifier }
    public var dsp: String? { nil }
}


final class MintegralBiddingInterstitialDemandProvider: MintegralBiddingBaseDemandProvider<MTGNewInterstitialBidAdManager> {
    private lazy var interstitial: MTGNewInterstitialBidAdManager = {
        let interstitial = MTGNewInterstitialBidAdManager(
            placementId: "",
            unitId: "",
            delegate: self
        )
        return interstitial
    }()
    
    override func prepareBid(
        with payload: String,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        interstitial.loadAd(withBidToken: payload)
    }
}


extension MintegralBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: MTGNewInterstitialBidAdManager, from viewController: UIViewController) {
        
    }
}


extension MintegralBiddingInterstitialDemandProvider: MTGNewInterstitialBidAdDelegate {
    
}
