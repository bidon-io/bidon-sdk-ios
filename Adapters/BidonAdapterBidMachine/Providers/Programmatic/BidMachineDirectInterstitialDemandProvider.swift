//
//  BidMachineInterstitialDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineDirectInterstitialDemandProvider: BidMachineBaseDemandProvider<BidMachineInterstitial>, DirectDemandProvider {
    override var placementFormat: PlacementFormat { .interstitial }

    func load(
        pricefloor: Price,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        var parameters = adUnitExtras.customParameters ?? [String: String]()
        parameters["mediation_mode"] = "bidon"

        let placement = try? BidMachineSdk.shared.placement(from: placementFormat) {
            if let placementId = adUnitExtras.placement {
                $0.withPlacementId(placementId)
            }
            $0.withCustomParameters(parameters)
        }

        guard let placement else {
            response(.failure(.unspecifiedException("No placement")))
            return
        }

        let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
            builder.appendPriceFloor(pricefloor, UUID().uuidString)
        }

        BidMachineSdk.shared.interstitial(request: request) { [weak self] ad, error in
            guard let self = self else { return }

            guard let ad = ad, error == nil else {
                response(.failure(.noFill(error?.localizedDescription)))
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


extension BidMachineDirectInterstitialDemandProvider: InterstitialDemandProvider {
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
