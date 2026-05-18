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
    override var adFormat: AdFormat { format.bmBannerFormat }

    weak var adViewDelegate: DemandProviderAdViewDelegate?

    override func load(
        payload: BidMachineBiddingPayload,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        var parameters = adUnitExtras.customParameters ?? [String: String]()
        parameters["mediation_mode"] = mediationMode

        let placement = try? BidMachineSdk.shared.placement(format.bmBannerFormat) {
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

    init(context: AdViewContext, mediationMode: String) {
        self.format = context.format

        super.init(mediationMode: mediationMode)
    }

    // MARK: - Override base class methods for banner-specific behavior

    override func didPresentAd(_ ad: BidMachineAdProtocol) {
        // NO-OP: Banner ads don't use providerWillPresent - that's for fullscreen ads only
    }

    override func didDismissAd(_ ad: BidMachineAdProtocol) {
        // NO-OP: Banner ads don't use providerDidHide - that's for fullscreen ads only
    }

    override func willPresentScreen(_ ad: BidMachineAdProtocol) {
        guard let ad = ad as? BidMachineBanner else {
            return
        }
        adViewDelegate?.providerWillPresentModalView(self, adView: ad)
    }

    override func didDismissScreen(_ ad: BidMachineAdProtocol) {
        guard let ad = ad as? BidMachineBanner else {
            return
        }
        adViewDelegate?.providerDidDismissModalView(self, adView: ad)
    }
}


extension BidMachineBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
