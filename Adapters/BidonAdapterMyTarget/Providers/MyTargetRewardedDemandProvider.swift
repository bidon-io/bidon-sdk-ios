//
//  MyTargetRewardedDemandProvider.swift
//  BidonAdapterMyTarget
//
//  Created by Evgenia Gorbacheva on 05/08/2024.
//

import UIKit
import Bidon
import MyTargetSDK

final class MyTargetRewardedDemandAd: DemandAd {
    var rewarded: MTRGRewardedAd
    public var id: String { return String(rewarded.hash) }

    init(rewarded: MTRGRewardedAd) {
        self.rewarded = rewarded
    }
}

final class MyTargetRewardedDemandProvider: MyTargetBaseDemandProvider<MyTargetRewardedDemandAd> {

    private var rewarded: MTRGRewardedAd?
    private var response: DemandProviderResponse?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    override func load(
        payload: MyTargetBiddingPayload,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let slotId = UInt(adUnitExtras.slotId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }

        self.response = response

        let rewarded = MTRGRewardedAd(slotId: slotId)
        synchronise(ad: rewarded, adUnitExtras: adUnitExtras)
        rewarded.delegate = self
        rewarded.load(fromBid: payload.bidId)

        self.rewarded = rewarded
    }

    override func load(
        pricefloor: Price,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let slotId = UInt(adUnitExtras.slotId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }

        self.response = response

        let rewarded = MTRGRewardedAd(slotId: slotId)
        synchronise(ad: rewarded, adUnitExtras: adUnitExtras)
        rewarded.delegate = self
        rewarded.load()

        self.rewarded = rewarded
    }
}

extension MyTargetRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: MyTargetRewardedDemandAd,
        from viewController: UIViewController
    ) {
        ad.rewarded.show(with: viewController)
    }
}

extension MyTargetRewardedDemandProvider: MTRGRewardedAdDelegate {
    func onLoad(with rewardedAd: MTRGRewardedAd) {
        let ad = MyTargetRewardedDemandAd(rewarded: rewardedAd)
        response?(.success(ad))
        response = nil
    }

    func onLoadFailed(error: Error, rewardedAd: MTRGRewardedAd) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func onReward(_ reward: MTRGReward, rewardedAd: MTRGRewardedAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }

    func onDisplay(with rewardedAd: MTRGRewardedAd) {
        delegate?.providerWillPresent(self)

        let ad = MyTargetRewardedDemandAd(rewarded: rewardedAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func onClick(with rewardedAd: MTRGRewardedAd) {
        delegate?.providerDidClick(self)
    }

    func onClose(with rewardedAd: MTRGRewardedAd) {
        delegate?.providerDidHide(self)
    }
}
