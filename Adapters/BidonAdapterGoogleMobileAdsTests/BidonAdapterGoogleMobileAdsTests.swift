import XCTest
import Bidon
import GoogleMobileAds
@testable import BidonAdapterGoogleMobileAds


final class BidonAdapterGoogleMobileAdsTests: XCTestCase {
    private func versionString(_ v: VersionNumber) -> String {
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    func testMetadata() {
        let adapter = GoogleMobileAdsDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "admob")
        XCTAssertEqual(adapter.name, "Google Mobile Ads")
        let expectedVersion = versionString(MobileAds.shared.versionNumber)
        XCTAssertEqual(adapter.sdkVersion, expectedVersion)
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = GoogleMobileAdsDemandSourceAdapter()

        // Direct providers
        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))

        // Bidding providers
        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = GoogleMobileAdsDemandSourceAdapter()
        XCTAssertFalse(adapter.isInitialized)
    }
}

