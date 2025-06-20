//
//  VungleBaseDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation
import Bidon
import VungleAdsSDK


final class VungleDemandAd<AdObject: VungleAdsSDK.BasePublicAd>: DemandAd {
    public var id: String { adObject.creativeId }

    let adObject: AdObject

    init(adObject: AdObject) {
        self.adObject = adObject
    }
}


class VungleBaseDemandProvider<AdObject: VungleAdsSDK.BasePublicAd>: NSObject, BiddingDemandProvider, DirectDemandProvider {
    typealias DemandAdType = VungleDemandAd<AdObject>

    private(set) var demandAd: VungleDemandAd<AdObject>!

    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    @Injected(\.context)
    var context: SdkContext

    var response: DemandProviderResponse?

    func collectBiddingToken(
        biddingTokenExtras: VungleBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        // Synchronize privacy data
        switch context.regulations.gdpr {
        case .applies:
            VunglePrivacySettings.setGDPRStatus(true)
        case .doesNotApply:
            VunglePrivacySettings.setGDPRStatus(false)
        default:
            break
        }

        switch context.regulations.coppa {
        case .yes:
            VunglePrivacySettings.setCOPPAStatus(true)
        case .no:
            VunglePrivacySettings.setCOPPAStatus(false)
        default:
            break
        }

        let token = VungleAds.getBiddingToken()

        response(.success(token))
    }

    func load(
        payload: VungleBiddingPayload,
        adUnitExtras: VungleAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        let adObject = adObject(placement: adUnitExtras.placementId)
        demandAd = VungleDemandAd(adObject: adObject)
        adObject.load(payload.payload)
    }

    func load(pricefloor: Price, adUnitExtras: VungleAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response
        let adObject = adObject(placement: adUnitExtras.placementId)
        demandAd = VungleDemandAd(adObject: adObject)
        adObject.load()
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}

    open func adObject(placement: String) -> AdObject {
        fatalError("VungleBaseDemandProvider is not able to create ad object")
    }
}
