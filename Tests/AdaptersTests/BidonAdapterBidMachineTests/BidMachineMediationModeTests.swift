//
//  BidMachineMediationModeTests.swift
//  BidonAdapterBidMachineTests
//
//  Created by Bidon Team on 14.05.2026.
//

import Foundation
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

    @Test(arguments: ["bidon", "bidmachine_plus"])
    func serverMediationModeTakesPriority(adapterMode: String) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let extras = try decoder.decode(
            BidMachineAdUnitExtras.self,
            from: Data(#"{"custom_parameters":{"mediation_mode":"prebid","custom_targeting":"fl_imwp=4.25"}}"#.utf8)
        )
        for parameters in parametersFromAllProviders(extras, mediationMode: adapterMode) {
            #expect(parameters == ["mediation_mode": "prebid", "custom_targeting": "fl_imwp=4.25"])
        }
    }

    @Test(arguments: ["bidon", "prebid"])
    func adapterModeIsFallbackWhenServerKeyIsAbsent(adapterMode: String) throws {
        for json in ["{}", #"{"customParameters":{}}"#, #"{"customParameters":{"custom_targeting":"fl_imwp=4.25"}}"#] {
            let extras = try JSONDecoder().decode(BidMachineAdUnitExtras.self, from: Data(json.utf8))
            for parameters in parametersFromAllProviders(extras, mediationMode: adapterMode) {
                #expect(parameters["mediation_mode"] == adapterMode)
                #expect(parameters["custom_targeting"] == extras.customParameters?["custom_targeting"])
            }
        }
    }

    private func parametersFromAllProviders(
        _ extras: BidMachineAdUnitExtras,
        mediationMode: String
    ) -> [[String: String]] {
        [
            BidMachineDirectInterstitialDemandProvider(mediationMode: mediationMode).customParameters(from: extras),
            BidMachineDirectRewardedAdDemandProvider(mediationMode: mediationMode).customParameters(from: extras),
            BidMachineDirectAdViewDemandProvider(context: AdViewContext(.banner), mediationMode: mediationMode).customParameters(from: extras),
            BidMachineBiddingInterstitialDemandProvider(mediationMode: mediationMode).customParameters(from: extras),
            BidMachineBiddingRewardedAdDemandProvider(mediationMode: mediationMode).customParameters(from: extras),
            BidMachineBiddingAdViewDemandProvider(context: AdViewContext(.banner), mediationMode: mediationMode).customParameters(from: extras)
        ]
    }
}
