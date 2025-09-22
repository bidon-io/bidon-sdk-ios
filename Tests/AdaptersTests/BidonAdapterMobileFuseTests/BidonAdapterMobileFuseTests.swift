//
//  BidonAdapterMobileFuseTests.swift
//  BidonAdapterMobileFuseTests
//
//  Created by Andrei Rudyk on 08/09/2025.
//

import XCTest
import Bidon
import MobileFuseSDK
@testable import BidonAdapterMobileFuse


final class BidonAdapterMobileFuseTests: XCTestCase {
    // Compile-time check: class conforms to required protocols (no instance needed)
    private func assertConformance<T>(_: T.Type, file: StaticString = #file, line: UInt = #line)
    where T: Adapter & BiddingInterstitialDemandSourceAdapter & BiddingRewardedAdDemandSourceAdapter & BiddingAdViewDemandSourceAdapter {
        // No-op: successful compilation confirms API conformance
    }

    func testMetadataStaticAndSdkVersion() throws {
        XCTAssertEqual(MobileFuseDemandSourceAdapter.identifier, "mobilefuse")
        // Ensure MobileFuse SDK version is available and non-empty
        if let version = MobileFuse.version() {
            XCTAssertFalse(version.isEmpty)
        } else {
            throw XCTSkip("MobileFuse SDK did not return version in this environment")
        }
    }

    func testProtocolConformance() {
        assertConformance(MobileFuseDemandSourceAdapter.self)
    }
}
