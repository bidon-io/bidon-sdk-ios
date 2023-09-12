//
//  InMobiDemandAd.swift
//  BidonAdapterInMobi
//
//  Created by Stas Kochkin on 11.09.2023.
//

import Foundation
import InMobiSDK
import Bidon


protocol InMobiAd {
    var placementId: Int64 { get }
}


final class InMobiDemandAd<Ad: InMobiAd>: NSObject, DemandAd {
    var id: String { String(ad.placementId) }
    var networkName: String { InMobiDemandSourceAdapter.identifier }
    var dsp: String? { nil }
    
    let ad: Ad
    
    init(ad: Ad) {
        self.ad = ad
        super.init()
    }
}
