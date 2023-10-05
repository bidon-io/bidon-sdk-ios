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
    
    func getAdMetaInfo() -> [String: Any]?
}


final class InMobiDemandAd<Ad: InMobiAd>: NSObject, DemandAd {
    var id: String {
        return String(ad.placementId)
    }
    
    var networkName: String {
        return InMobiDemandSourceAdapter.identifier
    }
    
    var eCPM: Price {
        return ad
            .getAdMetaInfo()
            .flatMap { $0["bidValue"] as? Float }
            .map { Price($0) } ??
            .unknown
    }
    
    var dsp: String? {
        return ad
            .getAdMetaInfo()
            .flatMap { $0["adSourceName"] as? String }
    }
    
    let ad: Ad
    
    init(ad: Ad) {
        self.ad = ad
        super.init()
    }
}
