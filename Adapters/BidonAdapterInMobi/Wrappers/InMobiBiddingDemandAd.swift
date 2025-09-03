//
//  InMobiBiddingDemandAd.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import InMobiSDK
import Bidon


final class InMobiBiddingDemandAd<Ad: InMobiAd>: NSObject, DemandAd {
    var id: String { String(ad.placementId) }

    var networkName: String {
        return (ad.getAdMetaInfo()? ["adSourceName"] as? String) ?? InMobiDemandSourceAdapter.identifier
    }

    let ad: Ad

    init(ad: Ad) {
        self.ad = ad
        super.init()
    }
}
