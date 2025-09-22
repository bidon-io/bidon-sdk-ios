//
//  BidonAdapterBidMachineTests.swift
//  BidonAdapterBidMachineTests
//
//  Created by Andrei Rudyk on 09/09/2025.
//

import XCTest
import Bidon
import BidMachine
@testable import BidonAdapterBidMachine


final class BidonAdapterBidMachineTests: XCTestCase {
    func testMetadata() {
        let adapter = BidMachineDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "bidmachine")
        XCTAssertEqual(adapter.name, "BidMachine")
        XCTAssertEqual(adapter.sdkVersion, BidMachineSdk.sdkVersion)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = BidMachineDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = BidMachineDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}
