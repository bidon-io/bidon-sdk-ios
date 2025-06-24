//
//  RewardedImpressionController.swift
//  Bidon
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import UIKit


final class RewardedImpressionController: NSObject, FullscreenImpressionController {
    weak var delegate: FullscreenImpressionControllerDelegate?

    private let provider: any RewardedAdDemandProvider

    var impression: Impression

    required init(bid: AnyRewardedAdBid) {
        let bid = bid.unwrapped()

        self.provider = bid.provider
        self.impression = FullscreenImpression(bid: bid)

        super.init()

        provider.delegate = self
        provider.rewardDelegate = self
    }

    func show(from context: UIViewController) {
        provider.show(opaque: impression.ad, from: context)
    }
}


extension RewardedImpressionController: DemandProviderDelegate {
    func providerWillPresent(_ provider: any DemandProvider) {
        delegate?.willPresent(&impression)
    }

    func providerDidHide(_ provider: any DemandProvider) {
        delegate?.didHide(&impression)
    }

    func providerDidClick(_ provider: any DemandProvider) {
        delegate?.didClick(&impression)
    }

    func provider(
        _ provider: any DemandProvider,
        didExpireAd ad: DemandAd
    ) {
        delegate?.didExpire(&impression)
    }

    func provider(
        _ provider: any DemandProvider,
        didFailToDisplayAd ad: DemandAd,
        error: SdkError
    ) {
        var optional = Optional.some(impression)
        delegate?.didFailToPresent(&optional, error: error)
    }
}


extension RewardedImpressionController: DemandProviderRewardDelegate {
    func provider(_ provider: any DemandProvider, didReceiveReward reward: Reward) {
        delegate?.didReceiveReward(reward, impression: &impression)
    }
}
