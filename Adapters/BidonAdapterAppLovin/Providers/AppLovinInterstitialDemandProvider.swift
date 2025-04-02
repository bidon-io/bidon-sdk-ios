//
//  AppLovinInterstitialDemandProvider.swift
//  BidonAdapterAppLovin
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import Bidon
import AppLovinSDK
import UIKit


internal final class AppLovinInterstitialDemandProvider: NSObject {
    private let sdk: ALSdk
    
    @Injected(\.bridge)
    var bridge: AppLovinAdServiceBridge
    
    private lazy var interstitial: ALInterstitialAd = {
        let interstitial = ALInterstitialAd(sdk: sdk)
        interstitial.adDisplayDelegate = self
        return interstitial
    }()
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    init(sdk: ALSdk) {
        self.sdk = sdk
        super.init()
    }
}


extension AppLovinInterstitialDemandProvider: DirectDemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtras: AppLovinAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        bridge.load(
            service: sdk.adService,
            zoneId: adUnitExtras.zoneId
        ) { result in
            switch result {
            case .success(let ad):
                response(.success(ad))
            case .failure(let error):
                response(.failure(error))
            }
        }
    }
    
    func notify(ad: ALAd, event: DemandProviderEvent) {}
}


extension AppLovinInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: ALAd, from viewController: UIViewController) {
        interstitial.show(ad)
    }
}


extension AppLovinInterstitialDemandProvider: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        delegate?.providerWillPresent(self)
        
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        delegate?.providerDidHide(self)
    }
    
    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        delegate?.providerDidClick(self)
    }
}
