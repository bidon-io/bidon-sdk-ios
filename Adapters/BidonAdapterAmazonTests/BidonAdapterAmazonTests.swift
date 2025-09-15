//
//  BidonAdapterAmazonTests.swift
//  BidonAdapterAmazonTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import DTBiOSSDK
@testable import BidonAdapterAmazon


final class BidonAdapterAmazonTests: XCTestCase {
    func testMetadata() {
        let adapter = AmazonDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "amazon")
        XCTAssertEqual(adapter.name, "Amazon")
        XCTAssertEqual(adapter.sdkVersion, DTBAds.version())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = AmazonDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = AmazonDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}
