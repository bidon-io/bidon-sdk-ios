//
//  DemandAdapter.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation

// MARK: Interstitial
public typealias AnyDirectInterstitialDemandProvider = any InterstitialDemandProvider & DirectDemandProvider
public typealias AnyBiddingInterstitialDemandProvider = any InterstitialDemandProvider & BiddingDemandProvider


public protocol DirectInterstitialDemandSourceAdapter: Adapter {
    func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider
}

public protocol BiddingInterstitialDemandSourceAdapter: Adapter {
    func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider
}

// MARK: Rewarded Ad
public typealias AnyDirectRewardedAdDemandProvider = any RewardedAdDemandProvider & DirectDemandProvider
public typealias AnyBiddingRewardedAdDemandProvider = any RewardedAdDemandProvider & BiddingDemandProvider


public protocol DirectRewardedAdDemandSourceAdapter: Adapter {
    func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider
}

public protocol BiddingRewardedAdDemandSourceAdapter: Adapter {
    func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider
}

// MARK: Ad View
public typealias AnyDirectAdViewDemandProvider = any AdViewDemandProvider & DirectDemandProvider
public typealias AnyBiddingAdViewDemandProvider = any AdViewDemandProvider & BiddingDemandProvider

public protocol DirectAdViewDemandSourceAdapter: Adapter {
    func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider
}

public protocol BiddingAdViewDemandSourceAdapter: Adapter {
    func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider
}
