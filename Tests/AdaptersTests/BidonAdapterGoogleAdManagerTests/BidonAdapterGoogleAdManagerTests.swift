//
//  BidonAdapterGoogleAdManagerTests.swift
//  BidonAdapterGoogleAdManagerTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import GoogleMobileAds
@testable import BidonAdapterGoogleAdManager


final class BidonAdapterGoogleAdManagerTests: XCTestCase {
    private func versionString(_ v: VersionNumber) -> String {
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    func testMetadata() {
        let adapter = GoogleAdManagerDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "gam")
        XCTAssertEqual(adapter.name, "Google Ad Manager")
        let expectedVersion = versionString(MobileAds.shared.versionNumber)
        XCTAssertEqual(adapter.sdkVersion, expectedVersion)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = GoogleAdManagerDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = GoogleAdManagerDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}
