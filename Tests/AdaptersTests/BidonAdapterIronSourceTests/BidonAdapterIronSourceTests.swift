//
//  BidonAdapterIronSourceTests.swift
//  BidonAdapterIronSourceTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import IronSource
@testable import BidonAdapterIronSource


final class BidonAdapterIronSourceTests: XCTestCase {
    func testMetadata() {
        let adapter = IronSourceDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "ironsource")
        XCTAssertEqual(adapter.name, "IronSource")
        XCTAssertEqual(adapter.sdkVersion, LevelPlay.sdkVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = IronSourceDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = IronSourceDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
