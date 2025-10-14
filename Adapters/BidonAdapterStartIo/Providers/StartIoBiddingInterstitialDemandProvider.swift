//
//  StartIoBiddingInterstitialDemandProvider.swift
//  BidonAdapterStartIo
//

import UIKit
import Bidon
import StartApp


final class StartIoInterstitialDemandAd: DemandAd {
    public let id: String
    public var interstitial: STAStartAppAd

    init(unitId: String, interstitial: STAStartAppAd) {
        self.id = unitId
        self.interstitial = interstitial
    }
}


final class StartIoBiddingInterstitialDemandProvider: StartIoBiddingBaseDemandProvider<StartIoInterstitialDemandAd> {
    private var response: Bidon.DemandProviderResponse?
    private var unitId: String = ""
    private var interstitial: STAStartAppAd?

    override func load(
        payload: StartIoBiddingResponse,
        adUnitExtras: StartIoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.unitId = adUnitExtras.tagId
        
        let interstitial = STAStartAppAd()
        let pref = STAAdPreferences()
        pref.adTag = adUnitExtras.tagId
        interstitial?.load(withDelegate: self, with: pref, adm: payload.payload)
        self.interstitial = interstitial
    }
}


extension StartIoBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: StartIoInterstitialDemandAd, from viewController: UIViewController) {
        if ad.interstitial.isReady() {
            ad.interstitial.show()
        } else {
            delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
        }
    }
}

extension StartIoBiddingInterstitialDemandProvider: STADelegateProtocol {
    func didLoad(_ ad: STAAbstractAd!) {
        guard let interstitial = ad as? STAStartAppAd else {
            response?(.failure(.adFormatNotSupported))
            return
        }

        let wrappedAd = StartIoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
        response?(.success(wrappedAd))
        response = nil
    }
    
    func failedLoad(_ ad: STAAbstractAd!, withError error: (any Error)!) {
        response?(.failure(.noFill(error?.localizedDescription)))
        response = nil
    }
    
    func didShow(_ ad: STAAbstractAd!) {
        delegate?.providerWillPresent(self)

        if let interstitial = ad as? STAStartAppAd {
            let wrappedAd = StartIoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }
    
    func failedShow(_ ad: STAAbstractAd!, withError error: (any Error)!) {
        guard let interstitial = ad as? STAStartAppAd else {
            return
        }
        let wrappedAd = StartIoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
        delegate?.provider(self, didFailToDisplayAd: wrappedAd, error: SdkError(error))
    }
    
    func didClose(_ ad: STAAbstractAd!) {
        delegate?.providerDidHide(self)
    }
    
    func didClick(_ ad: STAAbstractAd!) {
        delegate?.providerDidClick(self)
    }
}


