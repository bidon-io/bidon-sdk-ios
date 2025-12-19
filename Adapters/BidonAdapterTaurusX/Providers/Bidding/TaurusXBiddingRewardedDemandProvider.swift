//
//  TaurusXBiddingRewardedDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXBiddingRewardedDemandProvider: NSObject, BiddingDemandProvider {

    private var response: DemandProviderResponse?
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var rewardedAd: TaurusXRewarded?
    
    func collectBiddingToken(
        biddingTokenExtras: TaurusXBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        var tokens = [String: String]()
        let group = DispatchGroup()

        biddingTokenExtras.placementIds
            .filter { $0.format == .rewarded }
            .forEach { adUnit in
                group.enter()
                TaurusXBidManager.makeToken(adUnit.placementId) { token in
                    tokens[adUnit.placementId] = token
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

        rewardedAd = TaurusXRewarded()
        rewardedAd?.placementId = adUnitExtras.placementId
        rewardedAd?.delegate = self
        rewardedAd?.load(withPayload: payload.payload)
    }
    
    func notify(ad: TaurusXRewardedDemandAd, event: DemandProviderEvent) {}
}

extension TaurusXBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: TaurusXRewardedDemandAd,
        from viewController: UIViewController
    ) {
        guard let rewardedAd = rewardedAd, rewardedAd.isReady() else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .cancelled
            )
            return
        }
        rewardedAd.showAd(fromRootViewController: viewController)
    }
}

extension TaurusXBiddingRewardedDemandProvider: TaurusXRewardedDelegate {
    func adLoadFinish() {
        guard let rewardedAd else {
            response?(.failure(.noFill("Missing rewardedAd")))
            response = nil
            return
        }
        
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        response?(.success(ad))
        response = nil
    }

    func adLoadFailWithError(_ error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func adImpression() {
        guard let rewardedAd else { return }
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func adVideoComplete() {
        // Video completed - can be used for additional tracking if needed
    }

    func adRewarded(withName name: String, value: Int) {
        let reward = RewardWrapper(label: name, amount: Int(value), wrapped: name)
        rewardDelegate?.provider(self, didReceiveReward: reward)
    }
    
    func adClosed() {
        delegate?.providerDidHide(self)
    }
    
    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func adShowFailWithError(_ error: any Error) {
        guard let rewardedAd else { return }
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
    
    func adDismissed() {
        delegate?.providerDidHide(self)
    }
}
