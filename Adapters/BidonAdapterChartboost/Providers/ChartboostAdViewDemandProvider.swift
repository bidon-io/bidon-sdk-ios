//
//  ChartboostAdViewDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Евгения Григорович on 20/08/2024.
//

import UIKit
import Bidon
import ChartboostSDK

final class ChartboostAdViewDemandProvider: ChartboostBaseDemandProvider<ChartboostDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    var banner: CHBBanner?

    let adSize: CHBBannerSize

    init(context: AdViewContext, version: String) {
        self.rootViewController = context.rootViewController
        self.adSize = context.format.chartboostAdSize

        super.init(version: version)
    }

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

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.banner = CHBBanner(
                size: self.adSize,
                location: adUnitExtras.adLocation,
                mediation: mediation,
                delegate: self
            )
            self.banner?.cache()
        }
    }
}

extension ChartboostAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: ChartboostDemandAd) -> Bidon.AdViewContainer? {
        if let rootViewController {
            banner?.show(from: rootViewController)
        }
        return banner
    }

    func didTrackImpression(for ad: ChartboostDemandAd) { }
}

private extension BannerFormat {
    var chartboostAdSize: CHBBannerSize {
        switch self {
        case .banner:
            return CHBBannerSizeStandard
        case .leaderboard:
            return CHBBannerSizeLeaderboard
        case .mrec:
            return CHBBannerSizeMedium
        case .adaptive:
            return CHBBannerSize(width: self.preferredSize.width, height: self.preferredSize.height)
        }
    }
}

extension CHBBanner: Bidon.AdViewContainer {
    public var isAdaptive: Bool { true }
}
