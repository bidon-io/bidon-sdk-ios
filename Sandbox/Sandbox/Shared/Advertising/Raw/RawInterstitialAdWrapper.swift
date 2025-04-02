//
//  RawInterstitialAdWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 16.02.2023.
//

import Foundation
import Bidon
import Combine
import SwiftUI



final class RawInterstitialAdWrapper: BaseFullscreenAdWrapper {
    private var bidonInterstitial: Bidon.Interstitial?
    
    override var adType: AdType { .interstitial }
    
    override func _load() {
        let interstitial = Bidon.Interstitial(auctionKey: auctionKey)
        interstitial.delegate = self
        interstitial.loadAd(with: pricefloor)
        self.bidonInterstitial = interstitial
    }
    
    override func _show() {
        guard
            let controller = UIApplication.shared.bd.topViewcontroller
        else {
            resumeShowingContinuation(throwing: RawAdServiceError.invalidPresentationState)
            return
        }
        
        if let interstitial = bidonInterstitial, interstitial.isReady {
            interstitial.showAd(from: controller)
        } else {
            resumeShowingContinuation(throwing: RawAdServiceError.invalidPresentationState)
        }
    }
    
    override var isReady: Bool {
        return bidonInterstitial?.isReady == true
    }
    
    override func notify(win ad: Ad) {
        bidonInterstitial?.notifyWin()
    }
    
    override func notify(loss ad: Ad) {
        bidonInterstitial?.notifyLoss(
            external: "some_unknown_ad_network",
            price: ad.price + 0.01
        )
    }
}


extension RawInterstitialAdWrapper {
    override func adObject(_ adObject: Bidon.AdObject, didLoadAd ad: Bidon.Ad, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didLoadAd: ad, auctionInfo: auctionInfo)
        
        resumeLoadingContinuation()
    }
    
    override func adObject(_ adObject: Bidon.AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didFailToLoadAd: error, auctionInfo: auctionInfo)
        
        resumeLoadingContinuation(throwing: RawAdServiceError.noFill)
    }
    
    override func adObject(_ adObject: Bidon.AdObject, didFailToPresentAd error: Error) {
        super.adObject(adObject, didFailToPresentAd: error)
        
        resumeShowingContinuation(throwing: RawAdServiceError.invalidPresentationState)
    }
    
    override func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, didDismissAd ad: Bidon.Ad) {
        super.fullscreenAd(fullscreenAd, didDismissAd: ad)
        
        resumeShowingContinuation()
    }
}
