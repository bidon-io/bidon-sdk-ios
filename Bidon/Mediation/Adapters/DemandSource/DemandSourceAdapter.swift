//
//  DemandAdapter.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation

// MARK: Interstitial
public typealias AnyDirectInterstitialDemandProvider = any InterstitialDemandProvider & DirectDemandProvider
public typealias AnyProgrammaticInterstitialDemandProvider = any InterstitialDemandProvider & ProgrammaticDemandProvider
public typealias AnyBiddingInterstitialDemandProvider = any InterstitialDemandProvider & BiddingDemandProvider


public protocol DirectInterstitialDemandSourceAdapter: Adapter {
    func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider
}

public protocol ProgrammaticInterstitialDemandSourceAdapter: Adapter {
    func programmaticInterstitialDemandProvider() throws -> AnyProgrammaticInterstitialDemandProvider
}

public protocol BiddingInterstitialDemandSourceAdapter: Adapter {
    func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider
}

// MARK: Rewarded Ad
public typealias AnyDirectRewardedAdDemandProvider = any RewardedAdDemandProvider & DirectDemandProvider
public typealias AnyProgrammaticRewardedAdDemandProvider = any RewardedAdDemandProvider & ProgrammaticDemandProvider
public typealias AnyBiddingRewardedAdDemandProvider = any RewardedAdDemandProvider & BiddingDemandProvider


public protocol DirectRewardedAdDemandSourceAdapter: Adapter {
    func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider
}

public protocol ProgrammaticRewardedAdDemandSourceAdapter: Adapter {
    func programmaticRewardedAdDemandProvider() throws -> AnyProgrammaticRewardedAdDemandProvider
}

public protocol BiddingRewardedAdDemandSourceAdapter: Adapter {
    func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider
}

// MARK: Ad View
public typealias AnyDirectAdViewDemandProvider = any AdViewDemandProvider & DirectDemandProvider
public typealias AnyProgrammaticAdViewDemandProvider = any AdViewDemandProvider & ProgrammaticDemandProvider
public typealias AnyBiddingAdViewDemandProvider = any AdViewDemandProvider & BiddingDemandProvider

public protocol DirectAdViewDemandSourceAdapter: Adapter {
    func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider
}

public protocol ProgrammaticAdViewDemandSourceAdapter: Adapter {
    func programmaticAdViewDemandProvider(context: AdViewContext) throws -> AnyProgrammaticAdViewDemandProvider
}

public protocol BiddingAdViewDemandSourceAdapter: Adapter {
    func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider
}
