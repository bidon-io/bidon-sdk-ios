//
//  UnityAdsAdWrapper.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import Bidon
import UnityAds


protocol UnityAdsDemandAd: DemandAd {}


final class UADSPlacement: NSObject, UnityAdsDemandAd {
    public var id: String { placementId }

    let placementId: String

    init(_ placementId: String) {
        self.placementId = placementId
        super.init()
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(placementId)
        return hasher.finalize()
    }
}

extension UADSBannerView: UnityAdsDemandAd {
    public var id: String { placementId }
}
