//
//  TaurusXBiddingAdViewDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import Foundation
import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXBiddingAdViewDemandProvider: TaurusXBiddingBaseDemandProvider<TaurusXBannerDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    let context: AdViewContext

    private var bannerAd: TaurusXBanner?
    private var bannerView: UIView?

    private var taurusXAdSize: TAXBannerSize {
        if context.format == .mrec {
            return TAXBannerSize.MREC_300_250
        }
        return TAXBannerSize.BANNER_320_50
    }

    init(context: AdViewContext) {
        self.context = context
        super.init()
    }
    
    override func load(
        payload: TaurusXBiddingPayload,
        adUnitExtras: AdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.bannerAd = TaurusXBanner()
            self.bannerAd?.placementId = adUnitExtras.placementId
            self.bannerAd?.adSize = self.taurusXAdSize
            self.bannerAd?.delegate = self
            self.bannerAd?.load(withPayload: payload.payload)
        }
    }
    
}

extension TaurusXBiddingAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: TaurusXBannerDemandAd) -> Bidon.AdViewContainer? {
        return bannerView
    }

    func didTrackImpression(for ad: TaurusXBannerDemandAd) { }
}

extension TaurusXBiddingAdViewDemandProvider: TaurusXBannerDelegate {
    func adLoadFinish(_ bannerView: UIView) {
        guard let bannerAd else {
            response?(.failure(.noFill("No banner")))
            response = nil
            return
        }
        
        self.bannerView = bannerView
        let ad = TaurusXBannerDemandAd(bannerAd)
        response?(.success(ad))
        response = nil
    }

    func adLoadFailWithError(_ error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func adImpression() {
        guard let bannerAd else { return }
        let ad = TaurusXBannerDemandAd(bannerAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func adClicked() {
        delegate?.providerDidClick(self)
    }
}
