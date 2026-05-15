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

    override var adFormat: AdFormat { format.bmBannerFormat }

    func load(
        pricefloor: Price,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        var parameters = adUnitExtras.customParameters ?? [String: String]()
        parameters["mediation_mode"] = mediationMode

        let placement = try? BidMachineSdk.shared.placement(adFormat) {
            if let placementId = adUnitExtras.placement {
                $0.withPlacementId(placementId)
            }
            $0.withCustomParameters(parameters)
        }

        guard let placement else {
            response(.failure(.unspecifiedException("No placement")))
            return
        }

        if adUnitExtras.bapps != nil || adUnitExtras.bcat != nil || adUnitExtras.badv != nil {
            BidMachineSdk.shared.targetingInfo.populate { builder in
                if let bapps = adUnitExtras.bapps, !bapps.isEmpty {
                    builder.withBlockedApps(bapps)
                }
                if let bcat = adUnitExtras.bcat, !bcat.isEmpty {
                    builder.withBlockedCategories(bcat)
                }
                if let badv = adUnitExtras.badv, !badv.isEmpty {
                    builder.withBlockedAdvertisers(badv)
                }
            }
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


extension BidMachineDirectAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
