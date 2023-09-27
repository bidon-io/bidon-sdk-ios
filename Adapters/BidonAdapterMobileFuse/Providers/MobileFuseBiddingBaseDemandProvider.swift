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
    public var id: String { instanceId() }
    public var networkName: String { MobileFuseDemandSourceAdapter.identifier }
    public var dsp: String? { nil }
}


class MobileFuseBiddingBaseDemandProvider<DemandAdType: MFAd>: NSObject, ParameterizedBiddingDemandProvider, IMFAdCallbackReceiver {
    struct BiddingContext: Codable {
        var token: String
    }
    
    struct BiddingResponse: Decodable {
        var placementId: String
        var signal: String
        
        enum CodingKeys: String, CodingKey {
            case placementId
            case payload
        }
        
        private struct Payload: Decodable {
            var signaldata: String
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let payload = try container.decode(String.self, forKey: .payload)
            guard let payloadData = payload.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .payload,
                    in: container,
                    debugDescription: "Can't decode payload"
                )
            }
            
            signal = try JSONDecoder().decode(Payload.self, from: payloadData).signaldata
            placementId = try container.decode(String.self, forKey: .placementId)
        }
    }
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    var response: Bidon.DemandProviderResponse?
    
    @Injected(\.context)
    var context: SdkContext
    
    final func fetchBiddingContext(
        response: @escaping (Result<BiddingContext, MediationError>) -> ()
    ) {
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
                
        MFBiddingTokenProvider.getTokenWith(request) { token in
            let context = BiddingContext(token: token)
            response(.success(context))
        }
    }
    
    func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
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


