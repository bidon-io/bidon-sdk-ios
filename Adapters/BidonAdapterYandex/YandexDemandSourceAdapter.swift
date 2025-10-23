import Foundation
import Bidon
import YandexMobileAds

typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter

@objc public final class YandexDemandSourceAdapter: NSObject, DemandSourceAdapter {

    @objc public static let identifier = "yandex"

    public let demandId: String = YandexDemandSourceAdapter.identifier
    public let name: String = "Yandex"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = String(
        format: "%d.%d.%d",
        YMA_VERSION_MAJOR, YMA_VERSION_MINOR, YMA_VERSION_PATCH
    )
    
    private let bidderTokenLoader = BidderTokenLoader(mediationNetworkName: "MEDIATION_NETWORK_NAME")


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
}


extension YandexDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: YandexParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        if context.regulations.gdprApplies {
            MobileAds.setUserConsent(context.regulations.hasGdprConsent)
        }
        if context.regulations.coppaApplies {
            MobileAds.setAgeRestrictedUser(true)
        }

        MobileAds.initializeSDK { [weak self] in
            self?.isInitialized = true
            completion(nil)
        }
    }
}
