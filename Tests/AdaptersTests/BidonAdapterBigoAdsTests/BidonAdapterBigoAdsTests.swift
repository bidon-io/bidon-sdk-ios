import XCTest
import Bidon
import BigoADS
@testable import BidonAdapterBigoAds


final class BidonAdapterBigoAdsTests: XCTestCase {
    func testMetadata() {
        let adapter = BigoAdsDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "bigoads")
        XCTAssertEqual(adapter.name, "BigoAds")
        XCTAssertEqual(adapter.sdkVersion, BigoAdSdk.sharedInstance().getVersionName())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = BigoAdsDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))

        XCTAssertNotNil(try adapter.biddingInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.biddingRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.biddingAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = BigoAdsDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}
