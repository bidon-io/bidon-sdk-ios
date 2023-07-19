//
//  VungleBiddingAdViewDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation
import UIKit
import Bidon
import VungleAdsSDK


final class VungleAdViewContainer: UIView, AdViewContainer {
    var isAdaptive: Bool { false }
}


final class VungleBiddingAdViewDemandProvider: VungleBiddingBaseDemandProvider<VungleBanner> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?
    
    let adSize: BannerSize
    
    init(context: AdViewContext) {
        self.rootViewController = context.rootViewController
        self.adSize = BannerSize(format: context.format)
        
        super.init()
    }
    
    override func adObject() -> VungleBanner {
#warning("Placement is missing")
        let banner = VungleBanner(
            placementId: "placement",
            size: adSize
        )
        banner.delegate = self
        return banner
    }
}


extension VungleBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: VungleDemandAd<VungleBanner>) -> AdViewContainer? {
        let rect = CGRect(origin: .zero, size: adSize.cgSize)
        let container = VungleAdViewContainer(frame: rect)
        ad.adObject.present(on: container)
        return container
    }
    
    func didTrackImpression(for ad: VungleDemandAd<VungleAdsSDK.VungleBanner>) {}
}

extension VungleBiddingAdViewDemandProvider: VungleBannerDelegate {
    func bannerAdDidLoad(_ banner: VungleBanner) {
        guard demandAd.adObject === banner else { return }
        
        response?(.success(demandAd))
        response = nil
    }
    
    func bannerAdDidFailToLoad(_ banner: VungleBanner, withError: NSError) {
        guard demandAd.adObject === banner else { return }

        response?(.failure(.noFill))
        response = nil
    }
    
    func bannerAdDidFailToPresent(_ banner: VungleBanner, withError: NSError) {
        guard demandAd.adObject === banner else { return }

        delegate?.provider(
            self,
            didFailToDisplayAd: demandAd,
            error: .generic(error: withError)
        )
    }
    
    func bannerAdDidTrackImpression(_ banner: VungleBanner) {
        guard demandAd.adObject === banner else { return }

        revenueDelegate?.provider(self, didLogImpression: demandAd)
    }
    
    func bannerAdWillLeaveApplication(_ banner: VungleBanner) {
//        adViewDelegate?.providerWillLeaveApplication(self, adView: AdViewContainer)
    }
    
    func bannerAdDidClick(_ banner: VungleBanner) {
        guard demandAd.adObject === banner else { return }

        delegate?.providerDidClick(self)
    }
    
    func bannerAdDidClose(_ banner: VungleBanner) {
        guard demandAd.adObject === banner else { return }

        delegate?.providerDidHide(self)
    }
}


extension BannerSize {
    init(format: Bidon.BannerFormat) {
        switch format {
        case .banner, .adaptive:
            self = .regular
        case .leaderboard:
            self = .leaderboard
        case .mrec:
            self = .mrec
        }
    }
    
    var cgSize: CGSize {
        switch self {
        case .mrec:
            return CGSize(width: 300, height: 250)
        case .leaderboard:
            return CGSize(width: 728, height: 90)
        case .regular:
            return CGSize(width: 320, height: 50)
        case .short:
            return CGSize(width: 300, height: 50)
        @unknown default:
            return .zero
        }
    }
}
