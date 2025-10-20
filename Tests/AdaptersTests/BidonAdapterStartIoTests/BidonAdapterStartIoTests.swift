//
//  BidonAdapterStartIoTests.swift
//  BidonAdapterStartIoTests
//

import XCTest
import Bidon
import StartApp
@testable import BidonAdapterStartIo


final class BidonAdapterStartIoTests: XCTestCase {
    func testMetadata() {
        let adapter = StartIoDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "startio")
        XCTAssertEqual(adapter.name, "StartIo")
        XCTAssertEqual(adapter.sdkVersion, STAStartAppSDK.sharedInstance().version)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = StartIoDemandSourceAdapter()

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = StartIoDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}


