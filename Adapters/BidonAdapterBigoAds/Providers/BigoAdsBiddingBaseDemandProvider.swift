//
//  BigoAdsBiddingBaseDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


extension BigoAd: DemandAd {
    public var id: String { getCreativeId() }
    
    public var networkName: String { BigoAdsDemandSourceAdapter.identifier }
    
    public var dsp: String? {
        return nil
    }
}


class BigoAdsBiddingBaseDemandProvider<Ad: BigoAd>: NSObject, BiddingDemandProvider, BigoAdInteractionDelegate {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    typealias DemandAdType = Ad
    
    func collectBiddingToken(
        adUnitExtras: BigoAdsAdUnitExtras,
        response: @escaping (Result<BigoAdsBiddingToken, MediationError>) -> ()
    ) {
        let token = BigoAdSdk.sharedInstance().getBidderToken()
        
        guard !token.isEmpty else {
            response(.failure(.adapterNotInitialized))
            return
        }
        
        let context = BigoAdsBiddingToken(token: token)
        response(.success(context))
    }
    
    func load(
        payload: BigoAdsBiddingPayload,
        adUnitExtras: BigoAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("BigoAdsBiddingBaseDemandProvider is not able to create ad object")
    }
    
    func notify(
        ad: Ad,
        event: Bidon.DemandProviderEvent
    ) {
        switch event {
        case .lose:
            DispatchQueue.main.async {
                ad.destroy()
            }
        default:
            break
        }
    }
    
    func onAd(_ ad: BigoAd, error: BigoAdError) {
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .message(error.errorMsg)
        )
    }
    
    func onAdImpression(_ ad: BigoAd) {
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func onAdClicked(_ ad: BigoAd) {
        delegate?.providerDidClick(self)
    }
    
    func onAdOpened(_ ad: BigoAd) {
        delegate?.providerWillPresent(self)
    }
    
    func onAdClosed(_ ad: BigoAd) {
        delegate?.providerDidHide(self)
    }
}
