//
//  BigoAdsBaseDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


extension BigoAd: DemandAd {
    public var id: String { getCreativeId() ?? String(hash) }
}


class BigoAdsBaseDemandProvider<Ad: BigoAd>: NSObject, BiddingDemandProvider, DirectDemandProvider, BigoAdInteractionDelegate {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    typealias DemandAdType = Ad
    
    func collectBiddingToken(
        biddingTokenExtras: BigoAdsBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        guard let token = BigoAdSdk.sharedInstance().getBidderToken(), !token.isEmpty else {
            response(.failure(.adapterNotInitialized))
            return
        }
        
        response(.success(token))
    }
    
    func load(
        payload: BigoAdsBiddingPayload,
        adUnitExtras: BigoAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("BigoAdsBaseDemandProvider is not able to create ad object")
    }
    
    func load(pricefloor: Price, adUnitExtras: BigoAdsAdUnitExtras, response: @escaping DemandProviderResponse) {
        fatalError("BigoAdsBaseDemandProvider is not able to create ad object")
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
