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
    
    public var eCPM: Price {
        guard
            getBid() != nil,
            getBid().getPrice() != nil
        else {
            return .unknown
        }
        
        let price = Double(getBid().getPrice())
        return price * 1000
    }
}


class BigoAdsBiddingBaseDemandProvider<Ad: BigoAd>: NSObject, ParameterizedBiddingDemandProvider, BigoAdInteractionDelegate {
    struct BiddingContext: Codable {
        var token: String
    }
    
    struct BiddingResponse: Codable {
        var payload: String
        var slotId: String
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    typealias DemandAdType = Ad
    
    final func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        let token = BigoAdSdk.sharedInstance().getBidderToken()
        
        guard !token.isEmpty else {
            response(.failure(.adapterNotInitialized))
            return
        }
        
        let context = BiddingContext(token: token)
        response(.success(context))
    }
    
    func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("BigoAdsBiddingBaseDemandProvider is not able to create ad object")
    }
    
    func notify(
        ad: Ad,
        event: Bidon.AuctionEvent
    ) {
        switch event {
        case .lose:
            ad.destroy()
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
