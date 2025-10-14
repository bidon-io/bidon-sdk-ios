//
//  TaurusXParameters.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import Foundation

public struct TaurusXParameters: Codable {
    let channel: String
    let appId: String
    let adUnitIds: [TaurusXAdUnit]?
}

public struct TaurusXAdUnit: Codable {
    let placementId: String
    let format: TaurusXAdFormat
}

public enum TaurusXAdFormat: String, Codable {
    case interstitial = "INTERSTITIAL"
    case rewarded = "REWARDED"
    case banner = "BANNER"
    case mrec = "MREC"
}
