//
//  GoogleAdManagerRewardWrapper.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import GoogleMobileAds
import Bidon


typealias GoogleAdManagerRewardWrapper = RewardWrapper<GoogleMobileAds.AdReward>

extension GoogleAdManagerRewardWrapper {
    convenience init(_ reward: GoogleMobileAds.AdReward) {
        self.init(
            label: reward.type,
            amount: reward.amount.intValue,
            wrapped: reward
        )
    }
}
