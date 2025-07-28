//
//  BidMachineBiddingInterstitialDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineBiddingInterstitialDemandProvider: BidMachineBiddingDemandProvider<BidMachineInterstitial> {
    override var placementFormat: PlacementFormat { .interstitial }

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

        BidMachineSdk.shared.interstitial(request: request) { [weak self] ad, error in
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
}


extension BidMachineBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: BidMachineAdDemand<BidMachineInterstitial>, from viewController: UIViewController) {
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
