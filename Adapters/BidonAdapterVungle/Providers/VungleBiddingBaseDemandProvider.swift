//
//  VungleBiddingBaseDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation
import Bidon
import VungleAdsSDK


final class VungleDemandAd<AdObject: VungleAdsSDK.BasePublicAd>: DemandAd {
    public var id: String { adObject.creativeId }
    public var networkName: String { VungleDemandSourceAdapter.identifier }
    public var dsp: String? { return nil }
    
    let adObject: AdObject
    
    init(adObject: AdObject) {
        self.adObject = adObject
    }
}

class VungleBiddingBaseDemandProvider<AdObject: VungleAdsSDK.BasePublicAd>: NSObject, ParameterizedBiddingDemandProvider {
    typealias DemandAdType = VungleDemandAd<AdObject>
    
    struct BiddingContext: Codable {
        var token: String
    }
    
    lazy var demandAd = DemandAdType(adObject: adObject())
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    @Injected(\.context)
    var context: SdkContext
    
    var response: DemandProviderResponse?
    
    
    final func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        // Synchronize privacy data
        switch context.regulations.gdrpConsent {
        case .given:
            VunglePrivacySettings.setGDPRStatus(true)
        case .denied:
            VunglePrivacySettings.setGDPRStatus(false)
        default:
            break
        }
        
        switch context.regulations.coppaApplies {
        case .yes:
            VunglePrivacySettings.setCOPPAStatus(true)
        case .no:
            VunglePrivacySettings.setCOPPAStatus(false)
        default:
            break
        }
    
        let token = VungleAds.getBiddingToken()
        let context = BiddingContext(token: token)
        
        response(.success(context))
    }
    
    final func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        demandAd.adObject.load(payload)
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.AuctionEvent
    ) {}
    
    open func adObject() -> AdObject {
        fatalError("VungleBiddingBaseDemandProvider is not able to create ad object")
    }
}
