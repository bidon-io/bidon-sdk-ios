//
//  BidonAdapterUnityAdsTests.swift
//  BidonAdapterUnityAdsTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import UnityAds
import Bidon
@testable import BidonAdapterUnityAds


final class BidonAdapterUnityAdsTests: XCTestCase {
    func testMetadata() {
        let adapter = UnityAdsDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "unityads")
        XCTAssertEqual(adapter.name, "Unity Ads")
        XCTAssertEqual(adapter.sdkVersion, UnityAds.getVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = UnityAdsDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = UnityAdsDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}
