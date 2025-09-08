//
//  BidonAdapterMetaAudienceNetworkTests.swift
//  BidonAdapterMetaAudienceNetworkTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
import FBAudienceNetwork
@testable import BidonAdapterMetaAudienceNetwork


final class BidonAdapterMetaAudienceNetworkTests: XCTestCase {
    func testMetadata() {
        let adapter = MetaAudienceNetworkDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "meta")
        XCTAssertEqual(adapter.name, "MetaAudienceNetwork")
        XCTAssertEqual(adapter.sdkVersion, FB_AD_SDK_VERSION)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = MetaAudienceNetworkDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = MetaAudienceNetworkDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
