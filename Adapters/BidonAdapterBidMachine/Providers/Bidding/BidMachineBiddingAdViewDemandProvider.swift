//
//  BidMachineBiddingAdViewDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineBiddingAdViewDemandProvider: BidMachineBiddingDemandProvider<BidMachineBanner> {
    private let format: BannerFormat

    weak var adViewDelegate: DemandProviderAdViewDelegate?

    override var placementFormat: PlacementFormat { .init(format: format) }

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

        BidMachineSdk.shared.banner(request: request) { [weak self] ad, error in
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

    init(context: AdViewContext) {
        self.format = context.format

        super.init()
    }
}


extension BidMachineBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
