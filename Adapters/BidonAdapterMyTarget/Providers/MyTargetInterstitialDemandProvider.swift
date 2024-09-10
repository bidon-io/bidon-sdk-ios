//
//  MyTargetInterstitialDemandProvider.swift
//  BidonAdapterMyTarget
//
//  Created by Evgenia Gorbacheva on 05/08/2024.
//

import UIKit
import Bidon
import MyTargetSDK

final class MintegralInterstitialDemandAd: DemandAd {
    var interstitial: MTRGInterstitialAd
    public var id: String { return String(interstitial.hash) }
    
    init(interstitial: MTRGInterstitialAd) {
        self.interstitial = interstitial
    }
}

final class MyTargetInterstitialDemandProvider: MyTargetBaseDemandProvider<MintegralInterstitialDemandAd> {
    
    private var interstitial: MTRGInterstitialAd?
    private var response: DemandProviderResponse?

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
        
        let interstitial = MTRGInterstitialAd(slotId: slotId)
        synchronise(ad: interstitial, adUnitExtras: adUnitExtras)
        interstitial.delegate = self
        interstitial.load(fromBid: payload.bidId)
        
        self.interstitial = interstitial
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
        
        let interstitial = MTRGInterstitialAd(slotId: slotId)
        synchronise(ad: interstitial, adUnitExtras: adUnitExtras)
        interstitial.delegate = self
        interstitial.load()
        
        self.interstitial = interstitial
    }
}

extension MyTargetInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: MintegralInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        ad.interstitial.show(with: viewController)
    }
}

extension MyTargetInterstitialDemandProvider: MTRGInterstitialAdDelegate {
    func onLoad(with interstitialAd: MTRGInterstitialAd) {
        let ad = MintegralInterstitialDemandAd(interstitial: interstitialAd)
        response?(.success(ad))
        response = nil
    }
    
    func onLoadFailed(error: Error, interstitialAd: MTRGInterstitialAd) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func onDisplay(with interstitialAd: MTRGInterstitialAd) {
        delegate?.providerWillPresent(self)
        
        let ad = MintegralInterstitialDemandAd(interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func onClick(with interstitialAd: MTRGInterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func onClose(with interstitialAd: MTRGInterstitialAd) {
        delegate?.providerDidHide(self)
    }
}
