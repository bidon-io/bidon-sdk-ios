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

final class TaurusXBiddingAdViewDemandProvider: NSObject, BiddingDemandProvider {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

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
    
    func collectBiddingToken(
        biddingTokenExtras: TaurusXBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        var tokens = [String: String]()
        let group = DispatchGroup()

        biddingTokenExtras.placementIds
            .filter { $0.format == .banner }
            .forEach { adUnit in
                group.enter()
                TaurusXBidManager.makeToken(adUnit.placementId) { token, error in
                    if let token = token {
                        tokens[adUnit.placementId] = token
                    }
                    group.leave()
                }
            }

        group.notify(queue: .main) {
            if tokens.isEmpty {
                response(.failure(.unspecifiedException("No bidding tokens")))
            } else {
                do {
                    let data = try JSONSerialization.data(withJSONObject: tokens, options: [])
                    if let jsonString = String(data: data, encoding: .utf8) {
                        response(.success(jsonString))
                    } else {
                        response(.failure(.unspecifiedException("Mapping tokens error")))
                    }
                } catch {
                    response(.failure(.unspecifiedException("Mapping tokens error")))
                }
            }
        }
    }
    
    func load(
        payload: TaurusXBiddingPayload,
        adUnitExtras: TaurusXAdUnitExtras,
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
    
    func notify(ad: TaurusXBannerDemandAd, event: DemandProviderEvent) {}
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
