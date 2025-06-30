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
    @objc func bannerAdDidLoad(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }
        banner?.didMoveToSuperview()
        
        response?(.success(demandAd))
        response = nil
        
        hasAdLoaded = true
    }

    @objc func bannerAdWillPresent(_ bannerView: VungleAdsSDK.VungleBannerView) {}

    @objc func bannerAdDidPresent(_ bannerView: VungleAdsSDK.VungleBannerView) {}

    @objc func bannerAdDidFail(_ bannerView: VungleAdsSDK.VungleBannerView, withError: NSError) {
        guard demandAd.adObject === banner else { return }
        
        if hasAdLoaded {
            delegate?.provider(
                self,
                didFailToDisplayAd: demandAd,
                error: .generic(error: withError)
            )
        } else {
            response?(.failure(.noFill(withError.localizedDescription)))
            response = nil
        }
        
    }

    @objc func bannerAdWillClose(_ bannerView: VungleAdsSDK.VungleBannerView) {}

    @objc func bannerAdDidClose(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }
        
        delegate?.providerDidHide(self)
    }

    @objc func bannerAdDidTrackImpression(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }
        
        revenueDelegate?.provider(self, didLogImpression: demandAd)
    }

    @objc func bannerAdDidClick(_ bannerView: VungleAdsSDK.VungleBannerView) {
        guard demandAd.adObject === banner else { return }
        
        delegate?.providerDidClick(self)
    }

    @objc func bannerAdWillLeaveApplication(_ bannerView: VungleAdsSDK.VungleBannerView) {}
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


