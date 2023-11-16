//
//  RewardedAdDemandProvider.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 07.07.2022.
//

import Foundation


public protocol DemandProviderRewardDelegate: AnyObject {
    func provider(
        _ provider: any DemandProvider,
        didReceiveReward reward: Reward
    )
}


public protocol RewardedAdDemandProvider: InterstitialDemandProvider {
    var rewardDelegate: DemandProviderRewardDelegate? { get set }
}


typealias AnyRewardedAdDemandProvider = DemandProviderWrapper<(any RewardedAdDemandProvider)>
