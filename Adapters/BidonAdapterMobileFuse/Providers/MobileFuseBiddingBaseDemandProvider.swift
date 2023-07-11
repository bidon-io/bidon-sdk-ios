//
//  MobileFuseBaseBiddingDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Stas Kochkin on 11.07.2023.
//

import Foundation
import MobileFuseSDK
import Bidon


extension MFAd: DemandAd {
    public var id: String { instanceId() }
    public var networkName: String { MobileFuseDemandSourceAdapter.identifier }
    public var dsp: String? { nil }
    public var eCPM: Price { winningBidCpmPrice.doubleValue }
    public var currency: Currency { winningBidCurrency }
}


fileprivate struct MobileFuseBiddingContextEncoder: BiddingContextEncoder {
    let token: String
    
    init(token: String) {
        self.token = token
    }
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
    }
    
    func encodeBiddingContext(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
    }
}


class MobileFuseBiddingBaseDemandProvider<DemandAdType: MFAd>: NSObject, BiddingDemandProvider, IMFAdCallbackReceiver {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    var response: Bidon.DemandProviderResponse?
    
    @Injected(\.context)
    var context: SdkContext
    
    final func fetchBiddingContext(response: @escaping BiddingContextResponse) {
        let request = MFBiddingTokenRequest()
        request.isTestMode = context.isTestMode
        
        if let preferences = MobileFusePrivacyPreferences() {
            context.regulations.usPrivacyString.map(preferences.setUsPrivacyConsentString)
            context.regulations.gdprConsentString.map(preferences.setIabConsentString)
            
            switch context.regulations.coppaApplies {
            case .yes: preferences.setSubjectToCoppa(true)
            case .no: preferences.setSubjectToCoppa(false)
            default: break
            }
            
            request.privacyPreferences = preferences
        }
        
        if let token = MFBiddingTokenProvider.getTokenWith(request) {
            let encoder = MobileFuseBiddingContextEncoder(token: token)
            response(.success(encoder))
        } else {
            response(.failure(.adapterNotInitialized))
        }
    }
    
    func prepareBid(with payload: String, response: @escaping DemandProviderResponse) {
        fatalError("MobileFuseBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    func notify(
        ad: DemandAdType,
        event: Bidon.AuctionEvent
    ) {}
    
    
    final func onAdLoaded(_ ad: MFAd!) {
        guard let ad = ad as? DemandAdType else { return }
        response?(.success(ad))
        response = nil
    }
    
    final func onAdNotFilled(_ ad: MFAd!) {
        guard let _ = ad as? DemandAdType else { return }
        response?(.failure(.noFill))
        response = nil
    }
    
    final func onAdRendered(_ ad: MFAd!) {
        guard let ad = ad as? DemandAdType else { return }
        
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    final func onAdClicked(_ ad: MFAd!) {
        guard let _ = ad as? DemandAdType else { return }
        delegate?.providerDidClick(self)
    }
    
    final func onAdClosed(_ ad: MFAd!) {
        guard let _ = ad as? DemandAdType else { return }
        delegate?.providerDidHide(self)
    }
}


