//
//  AmazonAdUnitExtras.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation
import DTBiOSSDK
import Bidon

struct AmazonAdUnitExtras: Codable {
    enum Format: String, Codable {
        case interstitial = "INTERSTITIAL"
        case video = "VIDEO"
        case banner = "BANNER"
        case mrec = "MREC"
        case rewarded = "REWARDED"
    }

    var slotUuid: String
    var format: Format
    var isVideo: Bool?

    func adSize(_ format: BannerFormat? = nil) -> DTBAdSize? {
        switch (self.format, format) {
        case (.interstitial, _):
            return DTBAdSize(interstitialAdSizeWithSlotUUID: slotUuid)
        case (.video, _), (.rewarded, _):
            return DTBAdSize(videoAdSizeWithSlotUUID: slotUuid)
        case (.banner, .banner):
            return DTBAdSize(bannerAdSizeWithWidth: 320, height: 50, andSlotUUID: slotUuid)
        case (.banner, .leaderboard):
            return DTBAdSize(bannerAdSizeWithWidth: 728, height: 90, andSlotUUID: slotUuid)
        case (.mrec, .mrec):
            return DTBAdSize(bannerAdSizeWithWidth: 300, height: 250, andSlotUUID: slotUuid)
        case (.banner, .adaptive):
            if UIDevice.current.userInterfaceIdiom == .pad {
                return DTBAdSize(bannerAdSizeWithWidth: 728, height: 90, andSlotUUID: slotUuid)
            } else {
                return DTBAdSize(bannerAdSizeWithWidth: 320, height: 50, andSlotUUID: slotUuid)
            }
        default:
            return nil
        }
    }
}
