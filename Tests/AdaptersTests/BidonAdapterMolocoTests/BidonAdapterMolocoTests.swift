//
//  BidonAdapterMolocoTests.swift
//  BidonAdapterMolocoTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
@testable import BidonAdapterMoloco

final class BidonAdapterMolocoTests: XCTestCase {
    func testMetadata() {
        let adapter = MolocoDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "moloco")
        XCTAssertEqual(adapter.name, "Moloco")
        XCTAssertFalse(adapter.sdkVersion.isEmpty)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = MolocoDemandSourceAdapter()

        let interstitial = try adapter.biddingInterstitialDemandProvider()
        let rewarded = try adapter.biddingRewardedAdDemandProvider()
        let adView = try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner))

        XCTAssertNotNil(interstitial)
        XCTAssertNotNil(rewarded)
        XCTAssertNotNil(adView)
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = MolocoDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
