//
//  BaseFullscreenAdWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 20.02.2023.
//

import Foundation
import Bidon


class BaseFullscreenAdWrapper: BaseAdWrapper, FullscreenAdWrapper {
    private var loadingContinuation: CheckedContinuation<Void, Error>?
    private var showingContinuation: CheckedContinuation<Void, Error>?
    
    final private(set) var pricefloor: Double = .zero
        
    final func load(pricefloor: Double) async throws {
        self.pricefloor = pricefloor
        try await withCheckedThrowingContinuation { [unowned self] continuation in
            self.loadingContinuation = continuation
            DispatchQueue.main.async { [unowned self] in
                self._load()
            }
        }
    }
    
    final func show() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.showingContinuation = continuation
            DispatchQueue.main.async { [unowned self] in
                self._show()
            }
        }
    }
    
    var isReady: Bool {
        fatalError("Not implemented")
    }
    
    open func notify(loss ad: Ad) {
        fatalError("Not implemented")
    }
    
    open func notify(win ad: Ad) {
        fatalError("Not implemented")
    }
    
    open func _load() {
        fatalError("Not implemented")
    }
    
    open func _show() {
        fatalError("")
    }
    
    final func resumeLoadingContinuation(throwing error: Error) {
        loadingContinuation?.resume(throwing: error)
        loadingContinuation = nil
    }
    
    final func resumeLoadingContinuation() {
        loadingContinuation?.resume()
        loadingContinuation = nil
    }
    
    final func resumeShowingContinuation(throwing error: Error) {
        showingContinuation?.resume(throwing: error)
        showingContinuation = nil
    }
    
    final func resumeShowingContinuation() {
        showingContinuation?.resume()
        showingContinuation = nil
    }
}


extension BaseFullscreenAdWrapper: Bidon.RewardedAdDelegate {
    func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, willPresentAd ad: Bidon.Ad) {
        send(
            event: "Bidon will present ad",
            detail: ad.text,
            bage: "star.fill",
            color: .accentColor
        )
    }
    
    func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, didDismissAd ad: Bidon.Ad) {
        send(
            event: "Bidon did dismiss ad",
            detail: ad.text,
            bage: "star.fill",
            color: .secondary
        )
    }
    
    func rewardedAd(_ rewardedAd: RewardedAdObject, didRewardUser reward: Reward, ad: Ad) {
        send(
            event: "Bidon did reward user",
            detail: "Reward is \(reward.amount) \(reward.label)",
            bage: "gift",
            color: .orange
        )
    }
}
