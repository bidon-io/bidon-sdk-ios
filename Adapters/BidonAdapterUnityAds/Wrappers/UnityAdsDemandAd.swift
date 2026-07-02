//
//  UnityAdsAdWrapper.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import UIKit
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


final class UADSBannerAdContainer: UIView, UnityAdsDemandAd, AdViewContainer {
    var id: String { placementId }
    var isAdaptive: Bool { false }

    let placementId: String

    init(placementId: String, adView: UIView) {
        self.placementId = placementId
        super.init(frame: CGRect(origin: .zero, size: adView.frame.size))
        adView.frame = bounds
        adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(adView)
    }

    required init?(coder: NSCoder) { nil }
}
