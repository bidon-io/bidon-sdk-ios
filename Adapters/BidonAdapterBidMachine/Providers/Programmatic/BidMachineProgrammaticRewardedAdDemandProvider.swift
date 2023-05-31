//
//  BidMachineRewardedAdDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon


final class BidMachineProgrammaticRewardedAdDemandProvider: BidMachineProgrammaticDemandProvider<BidMachineRewarded> {
    fileprivate typealias EmptyReward = RewardWrapper<NSNull>
    
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override var placementFormat: BidMachineApiCore.PlacementFormat { .rewarded }
    
    override func didDismissAd(_ ad: BidMachineAdProtocol) {
        defer { super.didDismissAd(ad) }
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}


extension BidMachineProgrammaticRewardedAdDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: BidMachineAdDemand<BidMachineRewarded>,
        from viewController: UIViewController
    ) {
        guard ad.ad.canShow else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
            return
        }
        
        ad.ad.controller = viewController
        ad.ad.presentAd()
    }
}


private extension BidMachineProgrammaticRewardedAdDemandProvider.EmptyReward {
    convenience init() {
        self.init(
            label: "",
            amount: .zero,
            wrapped: NSNull()
        )
    }
}
