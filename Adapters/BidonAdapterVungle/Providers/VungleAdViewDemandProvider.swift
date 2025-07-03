//
//  VungleAdViewDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation
import UIKit
import Bidon
import VungleAdsSDK


final class VungleAdViewDemandProvider: VungleBaseDemandProvider<VungleBannerView> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    let adSize: VungleAdSize
    private weak var banner: VungleBannerView?

    private var hasAdLoaded = false


    init(context: AdViewContext) {
        self.rootViewController = context.rootViewController
        self.adSize = context.format.vungleAdSize

        super.init()
    }

    override func adObject(placement: String) -> VungleBannerView {
        let banner = VungleBannerView(
            placementId: placement,
            vungleAdSize: adSize
        )
        banner.delegate = self
        self.banner = banner
        return banner
    }
}


extension VungleAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: VungleDemandAd<VungleBannerView>) -> AdViewContainer? {
        return banner
    }

    func didTrackImpression(for ad: VungleDemandAd<VungleAdsSDK.VungleBannerView>) {}
}

extension VungleAdViewDemandProvider: VungleBannerViewDelegate {
    func bannerAdDidLoad(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }

        response?(.success(demandAd))
        response = nil

        hasAdLoaded = true
    }

    func bannerAdDidFail(_ bannerView: VungleAdsSDK.VungleBannerView, withError: NSError) {
        guard demandAd.adObject === banner else { return }

        response?(.failure(MediationError(error: withError)))
        response = nil

    }

    func bannerAdDidClose(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }

        delegate?.providerDidHide(self)
    }

    func bannerAdDidTrackImpression(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }

        revenueDelegate?.provider(self, didLogImpression: demandAd)
    }

    func bannerAdDidClick(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }

        delegate?.providerDidClick(self)
    }
}


extension VungleBannerView: @retroactive AdViewContainer {
    public var isAdaptive: Bool { false }
}


extension VungleBannerView: VungleLoadableAd {}


extension Bidon.BannerFormat {
    var vungleAdSize: VungleAdSize {
        switch self {
        case .banner, .adaptive:
            return .VungleAdSizeBannerRegular
        case .leaderboard:
            return .VungleAdSizeLeaderboard
        case .mrec:
            return .VungleAdSizeMREC
        @unknown default:
            return .VungleAdSizeBannerRegular
        }
    }
}


extension MediationError {
    init(error: NSError) {
        switch error.code {
        case 101, 102, 103, 104, 105, 106, 110, 111, 118, 119, 122, 124, 125, 134, 135, 138, 20001:
            self = .networkError
        case 208, 209, 214:
            self = .noBid(error.localizedDescription)
        case 213:
            self = .incorrectAdUnitId
        case 10001:
            self = .noFill(error.localizedDescription)
        default:
            self = .unspecifiedException("Code: \(error.code), \(error.localizedDescription)")
        }
    }
}
