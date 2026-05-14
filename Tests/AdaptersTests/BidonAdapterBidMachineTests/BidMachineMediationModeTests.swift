//
//  BidMachineMediationModeTests.swift
//  BidonAdapterBidMachineTests
//
//  Created by Bidon Team on 14.05.2026.
//

import Testing
import Bidon
@testable import BidonAdapterBidMachine


@Suite
struct BidMachineMediationModeTests {
    @Test
    func defaultInitializerUsesBidon() {
        let adapter = BidMachineDemandSourceAdapter()
        #expect(adapter.mediationMode == "bidon")
    }

    @Test
    func customInitializerStoresProvidedValue() {
        let adapter = BidMachineDemandSourceAdapter(mediationMode: "bidmachine_pro")
        #expect(adapter.mediationMode == "bidmachine_pro")
    }

    @Test
    func directProvidersReceiveAdapterMediationMode() throws {
        let adapter = BidMachineDemandSourceAdapter(mediationMode: "bidmachine_pro")

        let interstitial = try #require(
            try adapter.directInterstitialDemandProvider() as? BidMachineDirectInterstitialDemandProvider
        )
        let rewarded = try #require(
            try adapter.directRewardedAdDemandProvider() as? BidMachineDirectRewardedAdDemandProvider
        )
        let adView = try #require(
            try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)) as? BidMachineDirectAdViewDemandProvider
        )

        #expect(interstitial.mediationMode == "bidmachine_pro")
        #expect(rewarded.mediationMode == "bidmachine_pro")
        #expect(adView.mediationMode == "bidmachine_pro")
    }

    @Test
    func biddingProvidersReceiveAdapterMediationMode() throws {
        let adapter = BidMachineDemandSourceAdapter(mediationMode: "bidmachine_pro")

        let interstitial = try #require(
            try adapter.biddingInterstitialDemandProvider() as? BidMachineBiddingInterstitialDemandProvider
        )
        let rewarded = try #require(
            try adapter.biddingRewardedAdDemandProvider() as? BidMachineBiddingRewardedAdDemandProvider
        )
        let adView = try #require(
            try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)) as? BidMachineBiddingAdViewDemandProvider
        )

        #expect(interstitial.mediationMode == "bidmachine_pro")
        #expect(rewarded.mediationMode == "bidmachine_pro")
        #expect(adView.mediationMode == "bidmachine_pro")
    }

    @Test
    func defaultAdapterPropagatesBidonToProviders() throws {
        let adapter = BidMachineDemandSourceAdapter()

        let interstitial = try #require(
            try adapter.directInterstitialDemandProvider() as? BidMachineDirectInterstitialDemandProvider
        )
        let biddingAdView = try #require(
            try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)) as? BidMachineBiddingAdViewDemandProvider
        )

        #expect(interstitial.mediationMode == "bidon")
        #expect(biddingAdView.mediationMode == "bidon")
    }
}
