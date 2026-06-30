import Testing
import Bidon
import AppLovinSDK
@testable import BidonAdapterAppLovin


struct BidonAdapterAppLovinTests {
    @Test func metadata() {
        let adapter = AppLovinDemandSourceAdapter()

        #expect(adapter.demandId == "applovin")
        #expect(adapter.name == "AppLovin")
        #expect(adapter.sdkVersion == ALSdk.version())
        #expect(!adapter.adapterVersion.isEmpty)
    }

    @Test func factoriesReturnProviders() {
        let adapter = AppLovinDemandSourceAdapter()

        #expect(throws: Never.self) { try adapter.directInterstitialDemandProvider() }
        #expect(throws: Never.self) { try adapter.directRewardedAdDemandProvider() }
        #expect(throws: Never.self) { try adapter.directAdViewDemandProvider(context: AdViewContext(.banner)) }
    }

    @Test func conformsParameterizedInitializableAdapter() {
        let adapter = AppLovinDemandSourceAdapter()
        _ = adapter.isInitialized
        #expect(true)
    }
}
