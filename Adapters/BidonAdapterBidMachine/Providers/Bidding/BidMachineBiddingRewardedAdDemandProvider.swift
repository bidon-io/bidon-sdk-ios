//
//  BidMachineBiddingRewardedAdDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineBiddingRewardedAdDemandProvider: BidMachineBiddingDemandProvider<BidMachineRewarded> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    override var placementFormat: PlacementFormat { .rewarded }

    override func load(
        payload: BidMachineBiddingPayload,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        var parameters = adUnitExtras.customParameters ?? [String: String]()
        parameters["mediation_mode"] = "bidon"

        let placement = try? BidMachineSdk.shared.placement(from: placementFormat) {
            $0.withCustomParameters(parameters)
        }

        guard let placement else {
            response(.failure(.unspecifiedException("No placement")))
            return
        }

        let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
            builder.withPayload(payload.payload)
        }

        BidMachineSdk.shared.rewarded(request: request) { [weak self] ad, error in
            guard let self = self else { return }

            guard let ad = ad, error == nil else {
                response(.failure(.noBid(error?.localizedDescription)))
                return
            }

            ad.controller = UIApplication.shared.bd.topViewcontroller
            ad.delegate = self

            self.response = response
            self.ad = ad

            ad.loadAd()
        }
    }

    override func didDismissAd(_ ad: BidMachineAdProtocol) {
        defer { super.didDismissAd(ad) }

        rewardDelegate?.provider(self, didReceiveReward: BidMachineEmptyReward())
    }
}


extension BidMachineBiddingRewardedAdDemandProvider: RewardedAdDemandProvider {
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
