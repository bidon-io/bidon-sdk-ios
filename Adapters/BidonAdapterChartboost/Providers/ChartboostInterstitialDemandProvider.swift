//
//  ChartboostInterstitialDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Евгения Григорович on 20/08/2024.
//

import UIKit
import Bidon
import ChartboostSDK

final class ChartboostInterstitialDemandProvider: ChartboostBaseDemandProvider<ChartboostDemandAd> {

    private var response: DemandProviderResponse?
    private var interstitial: CHBInterstitial?

    override func load(
        pricefloor: Price,
        adUnitExtras: ChartboostAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        super.load(
            pricefloor: pricefloor,
            adUnitExtras: adUnitExtras,
            response: response
        )

        var mediation: CHBMediation?
        if let serverMediation = adUnitExtras.mediation {
            mediation = CHBMediation(name: serverMediation, libraryVersion: BidonSdk.sdkVersion, adapterVersion: version)
        }

        interstitial = CHBInterstitial(location: adUnitExtras.adLocation, mediation: mediation, delegate: self)
        interstitial?.cache()
    }
}

extension ChartboostInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: ChartboostDemandAd,
        from viewController: UIViewController
    ) {
        interstitial?.show(from: viewController)
    }
}
