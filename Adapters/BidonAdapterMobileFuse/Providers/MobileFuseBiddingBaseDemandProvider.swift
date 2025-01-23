//
//  MobileFuseBaseBiddingDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import MobileFuseSDK
import Bidon


extension MFAd: DemandAd {
    public var id: String { instanceId }
}


class MobileFuseBiddingBaseDemandProvider<DemandAdType: MFAd>: NSObject, BiddingDemandProvider, IMFAdCallbackReceiver {
    struct BiddingResponse: Decodable {
        var placementId: String
        var signal: String
        
        enum CodingKeys: String, CodingKey {
            case placementId
            case signal = "signaldata"
        }
    }
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    var response: Bidon.DemandProviderResponse?
    
    @Injected(\.context)
    var context: SdkContext
    
    func collectBiddingToken(
        biddingTokenExtras: MobileFuseBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let request = MFBiddingTokenRequest()
        request.isTestMode = context.isTestMode
        
        if let preferences = MobileFusePrivacyPreferences() {
            context.regulations.usPrivacyString.map(preferences.setUsPrivacyConsentString)
            context.regulations.gdprConsentString.map(preferences.setIabConsentString)
            
            switch context.regulations.coppa {
            case .yes: preferences.setSubjectToCoppa(true)
            case .no: preferences.setSubjectToCoppa(false)
            default: break
            }
            
            request.privacyPreferences = preferences
        }
                
        MFBiddingTokenProvider.getTokenWith(request) { token in
            response(.success(token))
        }
    }
    
    func load(
        payload: MobileFuseBiddingPayload,
        adUnitExtras: MobileFuseAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MobileFuseBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
    
    final func onAdLoaded(_ ad: MFAd!) {
        guard let ad = ad as? DemandAdType else { return }
        response?(.success(ad))
        response = nil
    }
    
    final func onAdNotFilled(_ ad: MFAd!) {
        guard let _ = ad as? DemandAdType else { return }
        response?(.failure(.noFill(nil)))
        response = nil
    }
    
    final func onAdError(_ ad: MFAd!, withError error: MFAdError!) {
        guard let _ = ad as? DemandAdType else { return }
        response?(.failure(.noFill(error.localizedDescription)))
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
    
    open func onUserEarnedReward(_ ad: MFAd!) {
        // No-op
    }
}


