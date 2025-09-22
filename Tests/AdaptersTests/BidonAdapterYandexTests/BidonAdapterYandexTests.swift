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

        let expected = String(format: "%d.%d.%d", YMA_VERSION_MAJOR, YMA_VERSION_MINOR, YMA_VERSION_PATCH)
        XCTAssertEqual(adapter.sdkVersion, expected)
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
