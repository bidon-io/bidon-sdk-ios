//
//  AppodealAdvertisingServiceInterstitialHelper.swift
//  Sandbox
//
//  Created by Bidon Team on 14.02.2023.
//

import Foundation
import Appodeal
import Bidon
import Combine
import SwiftUI


final class AppodealInterstitialAdWrapper: BaseFullscreenAdWrapper {
    private var bidonInterstitial: Bidon.Interstitial?
    
    override var adType: AdType { .interstitial } 
    
    override init() {
        super.init()
        Appodeal.setInterstitialDelegate(self)
    }
    
    override func _load() {
        performMediation()
    }
    
    override func _show() {
        guard
            let controller = UIApplication.shared.bd.topViewcontroller
        else {
            resumeShowingContinuation(throwing: AppodealAdServiceError.invalidPresentationState)
            return
        }
        
        if let interstitial = bidonInterstitial, interstitial.isReady {
            interstitial.showAd(from: controller)
        } else {
            Appodeal.showAd(.interstitial, rootViewController: controller)
        }
    }
    
    override var isReady: Bool {
        return Appodeal.isReadyForShow(with: .interstitial) || bidonInterstitial?.isReady == true
    }
    
    override func notify(win ad: Ad) {
        bidonInterstitial?.notifyWin()
    }
    
    override func notify(loss ad: Ad) {
        bidonInterstitial?.notifyLoss(
            external: "some_appodeal_ad_network",
            eCPM: ad.price + 0.1
        )
    }
    
    private func performMediation() {
        Appodeal.cacheAd(.interstitial)
    }
    
    private func performPostBid() {
        let pricefloor = max(pricefloor, Appodeal.predictedEcpm(for: .interstitial))
        let interstitial = Bidon.Interstitial()
        interstitial.delegate = self
        interstitial.loadAd(with: pricefloor)
        self.bidonInterstitial = interstitial
    }
}


extension AppodealInterstitialAdWrapper: AppodealInterstitialDelegate {
    func interstitialDidLoadAdIsPrecache(_ precache: Bool) {
        send(
            event: "Appodeal did load \(precache ? "precache" : "") ad",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
        
        performPostBid()
    }
    
    func interstitialDidFailToLoadAd() {
        send(
            event: "Appodeal did fail to load ad",
            detail: "",
            bage: "star.fill",
            color: .red
        )
        
        performPostBid()
    }
    
    func interstitialDidFailToPresent() {
        send(
            event: "Appodeal did fail to present ad",
            detail: "",
            bage: "star.fill",
            color: .red
        )
        
        resumeLoadingContinuation(throwing: AppodealAdServiceError.invalidPresentationState)
    }
    
    func interstitialDidClick() {
        send(
            event: "Appodeal did click",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
    }
    
    func interstitialWillPresent() {
        send(
            event: "Appodeal will present",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
    }
    
    func interstitialDidDismiss() {
        send(
            event: "Appodeal did dismiss ad",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
        
        resumeShowingContinuation()
    }
}


extension AppodealInterstitialAdWrapper {
    override func adObject(_ adObject: Bidon.AdObject, didLoadAd ad: Bidon.Ad, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didLoadAd: ad, auctionInfo: auctionInfo)
        
        resumeLoadingContinuation()
    }
    
    override func adObject(_ adObject: Bidon.AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didFailToLoadAd: error, auctionInfo: auctionInfo)
        
        if Appodeal.isReadyForShow(with: .interstitial) {
            resumeLoadingContinuation()
        } else {
            resumeLoadingContinuation(throwing: AppodealAdServiceError.noFill)
        }
    }

    
    override func adObject(_ adObject: Bidon.AdObject, didFailToPresentAd error: Error) {
        super.adObject(adObject, didFailToPresentAd: error)
        
        resumeShowingContinuation(throwing: AppodealAdServiceError.invalidPresentationState)
    }
    
    override func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, didDismissAd ad: Bidon.Ad) {
        super.fullscreenAd(fullscreenAd, didDismissAd: ad)
        
        resumeShowingContinuation()
    }
}
