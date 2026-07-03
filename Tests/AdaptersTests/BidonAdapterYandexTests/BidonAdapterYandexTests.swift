//
//  BidonAdapterYandexTests.swift
//  BidonAdapterYandexTests
//

import XCTest
import Bidon
import YandexMobileAds
@testable import BidonAdapterYandex


final class BidonAdapterYandexTests: XCTestCase {
    func testMetadata() {
        let adapter = YandexDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "yandex")
        XCTAssertEqual(adapter.name, "Yandex")

        // YMA_VERSION_* constants were removed in YandexMobileAds 8.x
        // (use MobileAds.sdkVersion instead); the adapter already reports
        // YandexAds.sdkVersion.stringValue, so just assert it is populated.
        XCTAssertFalse(adapter.sdkVersion.isEmpty)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = YandexDemandSourceAdapter()

        let interstitial = try adapter.directInterstitialDemandProvider()
        let rewarded = try adapter.directRewardedAdDemandProvider()
        let adView = try adapter.directAdViewDemandProvider(context: AdViewContext(.banner))

        XCTAssertNotNil(interstitial)
        XCTAssertNotNil(rewarded)
        XCTAssertNotNil(adView)
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = YandexDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
