//
//  AmazonBiddingRewardedDemandProvider.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 28.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK

final class AmazonBiddingRewardedDemandProvider: AmazonBiddingDemandProvider<DTBAdInterstitialDispatcher> {
    private lazy var dispatcher = DTBAdInterstitialDispatcher(delegate: self)
    private var response: DemandProviderResponse?

    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var handler: AmazonBiddingHandler?

    override func collectBiddingToken(biddingTokenExtras: AmazonBiddingTokenExtras, response: @escaping (Result<String, MediationError>) -> ()) {
        let adSizes = biddingTokenExtras.slots.filter({ $0.format == .rewarded }).compactMap({ $0.adSize() })
        handler = AmazonBiddingHandler(adSizes: adSizes)
        handler?.fetch(response: response)
    }

    override func load(
        payload: AmazonBiddingPayload,
        adUnitExtras: AmazonAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let adResponse = handler?.response(for: adUnitExtras.slotUuid) ?? AmazonHandlersStorage.fetch(for: adUnitExtras.slotUuid)
        else {
            response(.failure(.noAppropriateAdUnitId))
            return
        }

        fill(adResponse, response: response)
    }

    override func fill(
        _ data: DTBAdResponse,
        response: @escaping DemandProviderResponse
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.response = response
            self?.dispatcher.fetchAd(withParameters: data.mediationHints())
        }
    }
}


extension AmazonBiddingRewardedDemandProvider: InterstitialDemandProvider {
    func show(ad: DTBAdInterstitialDispatcher, from viewController: UIViewController) {
        ad.show(from: viewController)
    }
}


extension AmazonBiddingRewardedDemandProvider: RewardedAdDemandProvider {}


extension AmazonBiddingRewardedDemandProvider: DTBAdInterstitialDispatcherDelegate {
    func interstitialDidLoad(_ interstitial: DTBAdInterstitialDispatcher?) {
        guard let interstitial = interstitial else { return }
        response?(.success(interstitial))
        response = nil
    }

    func interstitial(
        _ interstitial: DTBAdInterstitialDispatcher?,
        didFailToLoadAdWith errorCode: DTBAdErrorCode
    ) {
        response?(.failure(MediationError(errorCode)))
        response = nil
    }

    func interstitialWillPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        delegate?.providerWillPresent(self)
    }

    func interstitialDidDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
        delegate?.providerDidHide(self)
    }

    func adClicked() {
        delegate?.providerDidClick(self)
    }

    func impressionFired() {
        revenueDelegate?.provider(self, didLogImpression: dispatcher)
    }

    // noop
    func interstitialDidPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func interstitialWillDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func interstitialWillLeaveApplication(_ interstitial: DTBAdInterstitialDispatcher?) {}
    func show(fromRootViewController controller: UIViewController) {}
}
