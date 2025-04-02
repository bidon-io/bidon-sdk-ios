//
//  AppodealRewardedAdAdvertisingWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 15.02.2023.
//

import Foundation
import Appodeal
import Bidon
import Combine
import SwiftUI


final class AppodealRewardedAdWrapper: BaseFullscreenAdWrapper {
    private var bidonRewardedAd: Bidon.RewardedAd?
    
    override var adType: AdType { .rewardedAd }
    
    override init() {
        super.init()
        Appodeal.setRewardedVideoDelegate(self)
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
        
        if let rewardedAd = bidonRewardedAd, rewardedAd.isReady {
            rewardedAd.showAd(from: controller)
        } else {
            Appodeal.showAd(.rewardedVideo, rootViewController: controller)
        }
    }
    
    override var isReady: Bool {
        return Appodeal.isReadyForShow(with: .rewardedVideo) || bidonRewardedAd?.isReady == true
    }
    
    override func notify(win ad: Ad) {
        bidonRewardedAd?.notifyWin()
    }
    
    override func notify(loss ad: Ad) {
        bidonRewardedAd?.notifyLoss(
            external: "some_unknown_ad_network",
            eCPM: ad.price + 0.01
        )
    }
    
    private func performMediation() {
        Appodeal.cacheAd(.rewardedVideo)
    }
    
    private func performPostBid() {
        let pricefloor = max(pricefloor, Appodeal.predictedEcpm(for: .rewardedVideo))
        let rewardedAd = Bidon.RewardedAd()
        rewardedAd.delegate = self
        rewardedAd.loadAd(with: pricefloor)
        self.bidonRewardedAd = rewardedAd
    }
}


extension AppodealRewardedAdWrapper: AppodealRewardedVideoDelegate {
    func rewardedVideoDidLoadAdIsPrecache(_ precache: Bool) {
        send(
            event: "Appodeal did load \(precache ? "precache" : "") ad",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
        
        performPostBid()
    }
    
    func rewardedVideoDidFailToLoadAd() {
        send(
            event: "Appodeal did fail to load ad",
            detail: "",
            bage: "star.fill",
            color: .red
        )
        
        performPostBid()
    }
    
    func rewardedVideoDidFailToPresentWithError(_ error: Error) {
        send(
            event: "Appodeal did fail to present ad",
            detail: "",
            bage: "star.fill",
            color: .red
        )
        
        resumeLoadingContinuation(throwing: AppodealAdServiceError.invalidPresentationState)
    }
    
    func rewardedVideoWillDismissAndWasFullyWatched(_ wasFullyWatched: Bool) {
        send(
            event: "Appodeal did dismiss ad",
            detail: "",
            bage: "star.fill",
            color: .secondary
        )
        
        resumeShowingContinuation()
    }
}


extension AppodealRewardedAdWrapper {
    override func adObject(_ adObject: Bidon.AdObject, didLoadAd ad: Bidon.Ad, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didLoadAd: ad, auctionInfo: auctionInfo)
        
        resumeLoadingContinuation()
    }
    
    override func adObject(_ adObject: Bidon.AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        super.adObject(adObject, didFailToLoadAd: error, auctionInfo: auctionInfo)
        
        if Appodeal.isReadyForShow(with: .rewardedVideo) {
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
