//
//  StartIoBiddingRewardedDemandProvider.swift
//  BidonAdapterStartIo
//

import UIKit
import Bidon
import StartApp


final class StartIoRewardedDemandAd: DemandAd {
    public let id: String
    public var rewarded: STAStartAppAd

    init(unitId: String, rewarded: STAStartAppAd) {
        self.id = unitId
        self.rewarded = rewarded
    }
}


final class StartIoBiddingRewardedDemandProvider: StartIoBiddingBaseDemandProvider<StartIoRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var response: Bidon.DemandProviderResponse?
    private var unitId: String = ""
    private var rewarded: STAStartAppAd?

    override func load(
        payload: StartIoBiddingResponse,
        adUnitExtras: StartIoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.unitId = adUnitExtras.adUnitId

        let rewarded = STAStartAppAd()
        let pref = STAAdPreferences()
        pref.adTag = adUnitExtras.adUnitId
        rewarded?.loadRewardedVideoAd(withDelegate: self, with: pref, adm: payload.payload)
        self.rewarded = rewarded
    }
}


extension StartIoBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: StartIoRewardedDemandAd, from viewController: UIViewController) {
        if ad.rewarded.isReady() {
            ad.rewarded.show()
        } else {
            delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
        }
    }
}


extension StartIoBiddingRewardedDemandProvider: STADelegateProtocol {
    func didLoad(_ ad: STAAbstractAd!) {
        guard let rewarded = ad as? STAStartAppAd else {
            response?(.failure(.adFormatNotSupported))
            return
        }

        let wrappedAd = StartIoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
        response?(.success(wrappedAd))
        response = nil
    }

    func failedLoad(_ ad: STAAbstractAd!, withError error: (any Error)!) {
        response?(.failure(.noFill(error?.localizedDescription)))
        response = nil
    }

    func didShow(_ ad: STAAbstractAd!) {
        delegate?.providerWillPresent(self)

        if let rewarded = ad as? STAStartAppAd {
            let wrappedAd = StartIoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }

    func failedShow(_ ad: STAAbstractAd!, withError error: (any Error)!) {
        guard let rewarded = ad as? STAStartAppAd else {
            return
        }
        let wrappedAd = StartIoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
        delegate?.provider(self, didFailToDisplayAd: wrappedAd, error: SdkError(error))
    }

    func didCompleteVideo(_ ad: STAAbstractAd!) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }

    func didClose(_ ad: STAAbstractAd!) {
        delegate?.providerDidHide(self)
    }

    func didClick(_ ad: STAAbstractAd!) {
        delegate?.providerDidClick(self)
    }
}


