//
//  BidonAdapterInMobiTests.swift
//  BidonAdapterInMobiTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import InMobiSDK
@testable import BidonAdapterInMobi


final class BidonAdapterInMobiTests: XCTestCase {
    func testMetadata() {
        let adapter = InMobiDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "inmobi")
        XCTAssertEqual(adapter.name, "InMobi")
        XCTAssertEqual(adapter.sdkVersion, IMSdk.getVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = InMobiDemandSourceAdapter()

        // Direct providers
        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))

        // Bidding providers
        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = InMobiDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
