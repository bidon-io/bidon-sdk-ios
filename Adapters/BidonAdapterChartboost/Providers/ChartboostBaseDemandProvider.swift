//
//  ChartboostBaseDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Евгения Григорович on 20/08/2024.
//

import Foundation
import Bidon
import ChartboostSDK

final class ChartboostDemandAd: DemandAd {
    public var id: String
    
    init(ad: CHBAd) {
        self.id = String(ad.hash)
    }
}

class ChartboostBaseDemandProvider<DemandAdType: DemandAd>: NSObject, DirectDemandProvider, CHBInterstitialDelegate, CHBRewardedDelegate, CHBBannerDelegate {
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    private var response: Bidon.DemandProviderResponse?
    let version: String
    
    init(version: String) {
        self.version = version
        super.init()
    }
    
    func load(
        pricefloor: Bidon.Price,
        adUnitExtras: ChartboostAdUnitExtras,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        self.response = response
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
    
    // MARK: - Ad Delegate (Interstitial & Rewarded & Banner)
    
    func didCacheAd(_ event: CHBCacheEvent, error: CacheError?) {
        if let error {
            response?(.failure(MediationError(error)))
            response = nil
            return
        }
        
        let ad = ChartboostDemandAd(ad: event.ad)
        response?(.success(ad))
        response = nil
    }
    
    func willShowAd(_ event: CHBShowEvent) {
        delegate?.providerWillPresent(self)
    }

    func didClickAd(_ event: CHBClickEvent, error: ClickError?) {
        delegate?.providerDidClick(self)
    }
    
    func didRecordImpression(_ event: CHBImpressionEvent) {
        let ad = ChartboostDemandAd(ad: event.ad)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    // MARK: - Ad Delegate (Interstitial & Rewarded)
    
    func didDismissAd(_ event: CHBDismissEvent) {
        delegate?.providerDidHide(self)
    }
    
    // MARK: - Ad Delegate (Rewarded)
    
    func didEarnReward(_ event: CHBRewardEvent) {
        rewardDelegate?.provider(self, didReceiveReward: RewardWrapper(label: "", amount: event.reward, wrapped: event))
    }
}

extension Bidon.MediationError {
    init(_ error: CacheError) {
        guard let code = error.cacheCode else {
            self = .unscpecifiedException("Unknown error")
            return
        }
        switch code {
        case .internalError:
            self = .unscpecifiedException("Internal Error")
        case .internetUnavailable, .networkFailure:
            self = .networkError
        case .noAdFound:
            self = .noFill("No Ad Found")
        case .sessionNotStarted:
            self = .adapterNotInitialized
        case .assetDownloadFailure:
            self = .noFill("Asset Download Failure")
        case .publisherDisabled:
            self = .unscpecifiedException("Publisher Disabled")
        case .serverError:
            self = .unscpecifiedException("Server Error")
        @unknown default:
            self = .unscpecifiedException("Unknown error")
        }
    }
}
