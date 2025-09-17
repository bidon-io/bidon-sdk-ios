//
//  BidonAdapterMyTargetTests.swift
//  BidonAdapterMyTargetTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
import MyTargetSDK
@testable import BidonAdapterMyTarget


final class BidonAdapterMyTargetTests: XCTestCase {
    func testMetadata() {
        let adapter = MyTargetDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "vkads")
        XCTAssertEqual(adapter.name, "MyTarget")
        XCTAssertEqual(adapter.sdkVersion, MTRGVersion.currentVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = MyTargetDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = MyTargetDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
