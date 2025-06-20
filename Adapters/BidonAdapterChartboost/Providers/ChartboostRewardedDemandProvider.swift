//
//  ChartboostRewardedDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Евгения Григорович on 20/08/2024.
//

import UIKit
import Bidon
import ChartboostSDK

final class ChartboostRewardedDemandProvider: ChartboostBaseDemandProvider<ChartboostDemandAd> {

    var rewarded: CHBRewarded?

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

        rewarded = CHBRewarded(location: adUnitExtras.adLocation, mediation: mediation, delegate: self)
        rewarded?.cache()
    }
}

extension ChartboostRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: ChartboostDemandAd,
        from viewController: UIViewController
    ) {
        rewarded?.show(from: viewController)
    }
}
