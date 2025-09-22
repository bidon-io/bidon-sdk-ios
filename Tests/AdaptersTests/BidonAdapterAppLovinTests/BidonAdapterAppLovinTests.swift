import XCTest
import Bidon
import AppLovinSDK
@testable import BidonAdapterAppLovin


final class BidonAdapterAppLovinTests: XCTestCase {
    func testMetadata() {
        let adapter = AppLovinDemandSourceAdapter()

        XCTAssertEqual(adapter.demandId, "applovin")
        XCTAssertEqual(adapter.name, "AppLovin")
        XCTAssertEqual(adapter.sdkVersion, ALSdk.version())
        XCTAssertFalse(adapter.adapterVersion.isEmpty)
    }

    func testFactoriesReturnProviders() throws {
        let adapter = AppLovinDemandSourceAdapter()

        XCTAssertNotNil(try adapter.directInterstitialDemandProvider())
        XCTAssertNotNil(try adapter.directRewardedAdDemandProvider())
        XCTAssertNotNil(try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)))
    }

    func testConformsParameterizedInitializableAdapter() {
        let adapter = AppLovinDemandSourceAdapter()
        _ = adapter.isInitialized
        XCTAssertTrue(true)
    }
}


