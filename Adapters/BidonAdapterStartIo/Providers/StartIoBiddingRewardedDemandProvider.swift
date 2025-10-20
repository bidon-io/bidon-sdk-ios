//
//  StartIoBiddingRewardedDemandProvider.swift
//  BidonAdapterStartIo
//

import UIKit
import Bidon
import StartApp


final class StartIoRewardedDemandAd: DemandAd {
    public var id: String { return String(rewarded.hash) }
    public var rewarded: STAStartAppAd

    init(rewarded: STAStartAppAd) {
        self.rewarded = rewarded
    }
}


final class StartIoBiddingRewardedDemandProvider: StartIoBiddingBaseDemandProvider<StartIoRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var response: Bidon.DemandProviderResponse?
    private var rewarded: STAStartAppAd?

    override func load(
        payload: StartIoBiddingResponse,
        adUnitExtras: StartIoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let rewarded = STAStartAppAd()
        let pref = STAAdPreferences()
        pref.adTag = adUnitExtras.tagId
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
            response = nil
            return
        }

        let wrappedAd = StartIoRewardedDemandAd(rewarded: rewarded)
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
            let wrappedAd = StartIoRewardedDemandAd(rewarded: rewarded)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }

    func failedShow(_ ad: STAAbstractAd!, withError error: (any Error)!) {
        guard let rewarded = ad as? STAStartAppAd else {
            return
        }
        let wrappedAd = StartIoRewardedDemandAd(rewarded: rewarded)
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


