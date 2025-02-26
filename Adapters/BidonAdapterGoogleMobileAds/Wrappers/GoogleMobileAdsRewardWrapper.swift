//
//  BDGADAdRewardWrapper.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 07.07.2022.
//

import Foundation
import GoogleMobileAds
import Bidon


typealias GoogleMobileAdsRewardWrapper = RewardWrapper<GADAdReward>

extension GoogleMobileAdsRewardWrapper {
    convenience init(_ reward: GADAdReward) {
        self.init(
            label: reward.type,
            amount: reward.amount.intValue,
            wrapped: reward
        )
    }
}
