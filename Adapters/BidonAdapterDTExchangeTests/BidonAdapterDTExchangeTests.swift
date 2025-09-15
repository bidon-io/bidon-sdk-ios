//
//  BidonAdapterDTExchangeTests.swift
//  BidonAdapterDTExchangeTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import IASDKCore
@testable import BidonAdapterDTExchange


final class BidonAdapterDTExchangeTests: XCTestCase {
    func testMetadata() {
        let adapter = DTExchangeDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "dtexchange")
        XCTAssertEqual(adapter.name, "DT Exchange")
        XCTAssertEqual(adapter.sdkVersion, IASDKCore.sharedInstance().version())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = DTExchangeDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = DTExchangeDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}
