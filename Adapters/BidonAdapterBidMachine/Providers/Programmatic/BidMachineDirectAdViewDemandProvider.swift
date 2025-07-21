//
//  BidMachineAdViewDemandSourceAdapter.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineDirectAdViewDemandProvider: BidMachineBaseDemandProvider<BidMachineBanner>, DirectDemandProvider {
    private let format: BannerFormat

    weak var adViewDelegate: DemandProviderAdViewDelegate?

    override var placementFormat: PlacementFormat { .init(format: format) }

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

        BidMachineSdk.shared.banner(request: request) { [weak self] ad, error in
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

    init(context: AdViewContext) {
        self.format = context.format

        super.init()
    }
}


extension BidMachineDirectAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
