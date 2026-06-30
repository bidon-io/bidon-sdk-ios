import Foundation
import Bidon
import YandexMobileAds

typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter

@objc public final class YandexDemandSourceAdapter: NSObject, DemandSourceAdapter {

    @objc public static let identifier = "yandex"

    public let demandId: String = YandexDemandSourceAdapter.identifier
    public let name: String = "Yandex"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = String(
        format: "%d.%d.%d",
        YMA_VERSION_MAJOR, YMA_VERSION_MINOR, YMA_VERSION_PATCH
    )

    private(set) public var isInitialized: Bool = false

    @Injected(\.context)
    var context: SdkContext

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return YandexDirectInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return YandexDirectRewardedDemandProvider()
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return YandexDirectAdViewDemandProvider(context: context)
    }

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return YandexBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return YandexBiddingRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return YandexBiddingAdViewDemandProvider(context: context)
    }
}


extension YandexDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: YandexParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        if context.regulations.gdprApplies {
            YandexAds.setUserConsent(context.regulations.hasGdprConsent)
        }
        if context.regulations.coppaApplies {
            YandexAds.setAgeRestricted(true)
        }

        YandexAds.initializeSDK()
        isInitialized = true
        completion(nil)
    }
}
