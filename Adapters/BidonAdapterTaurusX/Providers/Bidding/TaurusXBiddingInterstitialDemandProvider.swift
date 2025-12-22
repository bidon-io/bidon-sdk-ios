//
//  TaurusXBiddingInterstitialDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXBiddingInterstitialDemandProvider: NSObject, BiddingDemandProvider {
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var response: DemandProviderResponse?
    private var interstitialAd: TaurusXInterstitial?
    
    func load(
        payload: TaurusXBiddingPayload,
        adUnitExtras: TaurusXAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        self.interstitialAd = TaurusXInterstitial()
        self.interstitialAd?.placementId = adUnitExtras.placementId
        self.interstitialAd?.delegate = self
        self.interstitialAd?.load(withPayload: payload.payload)
    }
    
    func collectBiddingToken(
        biddingTokenExtras: TaurusXBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        var tokens = [String: String]()
        let group = DispatchGroup()

        biddingTokenExtras.placementIds
            .filter { $0.format == .interstitial }
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
    
    func notify(ad: TaurusXDemandAd, event: DemandProviderEvent) {}
}

extension TaurusXBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    
    func show(ad: TaurusXDemandAd, from viewController: UIViewController) {
        guard self.interstitialAd?.isReady() == true else {
            return
        }
        self.interstitialAd?.showAd(fromRootViewController: viewController)
    }
}

extension TaurusXBiddingInterstitialDemandProvider: TaurusXInterstitialDelegate {

    func adLoadFinish() {
        guard let interstitialAd else {
            response?(.failure(.noFill("No ad")))
            response = nil
            return
        }
        response?(.success(TaurusXDemandAd(interstitialAd)))
        response = nil
    }
    
    func adLoadFailWithError(_ error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func adImpression() {
        guard let interstitialAd else {
            return
        }
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: TaurusXDemandAd(interstitialAd))
    }
    
    func adShowFailWithError(_ error: any Error) {
        guard let interstitialAd else {
            return
        }
        delegate?.provider(
            self,
            didFailToDisplayAd: TaurusXDemandAd(interstitialAd),
            error: .generic(error: error)
        )
    }
    
    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func adDismissed() {
        delegate?.providerDidHide(self)
    }
}
