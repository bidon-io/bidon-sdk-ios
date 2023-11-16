//
//  VungleBiddingBaseDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
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


class VungleBiddingBaseDemandProvider<AdObject: VungleAdsSDK.BasePublicAd>: NSObject, BiddingDemandProvider {
    typealias DemandAdType = VungleDemandAd<AdObject>

    private(set) var demandAd: VungleDemandAd<AdObject>!
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    @Injected(\.context)
    var context: SdkContext
    
    var response: DemandProviderResponse?
    
    func collectBiddingToken(
        adUnitExtras: [VungleAdUnitExtras],
        response: @escaping (Result<VungleBiddingToken, MediationError>) -> ()
    ) {
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
        let context = VungleBiddingToken(token: token)
        
        response(.success(context))
    }
    
    func load(
        payload: VungleBiddingPayload,
        adUnitExtras: VungleAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        let adObject = adObject(placement: adUnitExtras.placementId)
        adObject.load(payload.payload)
        demandAd = VungleDemandAd(adObject: adObject)
        
        adObject.load(payload.payload)
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
    
    open func adObject(placement: String) -> AdObject {
        fatalError("VungleBiddingBaseDemandProvider is not able to create ad object")
    }
}
