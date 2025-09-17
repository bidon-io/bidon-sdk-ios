//
//  BidonAdapterMintegralTests.swift
//  BidonAdapterMintegralTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
import MTGSDK
@testable import BidonAdapterMintegral


final class BidonAdapterMintegralTests: XCTestCase {
    func testMetadata() {
        let adapter = MintegralDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "mintegral")
        XCTAssertEqual(adapter.name, "Mintegral")
        XCTAssertEqual(adapter.sdkVersion, MTGSDKVersion)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = MintegralDemandSourceAdapter()

        // Bidding providers
        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))

        // Direct providers
        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = MintegralDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
