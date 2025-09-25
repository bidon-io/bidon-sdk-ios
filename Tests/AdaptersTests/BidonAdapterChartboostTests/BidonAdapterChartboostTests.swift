//
//  BidonAdapterChartboostTests.swift
//  BidonAdapterChartboostTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import ChartboostSDK
@testable import BidonAdapterChartboost


final class BidonAdapterChartboostTests: XCTestCase {
    func testMetadata() {
        let adapter = ChartboostDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "chartboost")
        XCTAssertEqual(adapter.name, "Chartboost")
        XCTAssertEqual(adapter.sdkVersion, Chartboost.getSDKVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = ChartboostDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = ChartboostDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
