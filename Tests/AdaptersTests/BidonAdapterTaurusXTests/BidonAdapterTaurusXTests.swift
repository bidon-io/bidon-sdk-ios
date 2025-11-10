//
//  BidonAdapterTaurusXTests.swift
//  Tests
//
//  Created by Евгения Григорович on 01/10/2025.
//

import XCTest
import Bidon
import TaurusxAdsSDK
@testable import BidonAdapterTaurusX


final class BidonAdapterTaurusXTests: XCTestCase {
    func testMetadata() {
        let adapter = TaurusXDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "taurusx")
        XCTAssertEqual(adapter.name, "TaurusX")
        XCTAssertEqual(adapter.sdkVersion, TaurusXAds.sdkVersion())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = TaurusXDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
    }
    
    func testConformsParameterizedInitializableAdapter() {
        let adapter = TaurusXDemandSourceAdapter()
        let isInitialized = adapter.isInitialized
        XCTAssertFalse(isInitialized)
    }
}
