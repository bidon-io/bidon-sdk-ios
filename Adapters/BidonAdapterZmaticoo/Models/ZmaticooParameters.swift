//
//  ZmaticooParameters.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Foundation

public struct ZmaticooParameters: Codable {
    let appKey: String
    let placementIds: [ZmaticooAdUnit]?
}

public struct ZmaticooAdUnit: Codable {
    let placementId: String
    let format: ZmaticooAdFormat
}

public enum ZmaticooAdFormat: String, Codable {
    case interstitial = "INTERSTITIAL"
    case rewarded = "REWARDED"
    case banner = "BANNER"
    case mrec = "MREC"
}
