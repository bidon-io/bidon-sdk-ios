//
//  BidonAdapterVungleTests.swift
//  BidonAdapterVungleTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
import VungleAdsSDK
@testable import BidonAdapterVungle


final class BidonAdapterVungleTests: XCTestCase {
    func testMetadata() {
        let adapter = VungleDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "vungle")
        XCTAssertEqual(adapter.name, "Vungle")
        XCTAssertEqual(adapter.sdkVersion, VungleAds.sdkVersion)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = VungleDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = VungleDemandSourceAdapter()
        _ = adapter.isInitialized 
        XCTAssertTrue(true)
    }
}
