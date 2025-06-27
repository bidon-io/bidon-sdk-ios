import Foundation
import Bidon
import ChartboostSDK

typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter

@objc public final class ChartboostDemandSourceAdapter: NSObject, DemandSourceAdapter {

    @objc public static let identifier = "chartboost"

    public let demandId: String = ChartboostDemandSourceAdapter.identifier
    public let name: String = "Chartboost"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = Chartboost.getSDKVersion()

    private(set) public var isInitialized: Bool = false

    @Injected(\.context)
    var context: SdkContext

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return ChartboostInterstitialDemandProvider(version: adapterVersion)
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return ChartboostRewardedDemandProvider(version: adapterVersion)
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return ChartboostAdViewDemandProvider(context: context, version: adapterVersion)
    }
}


extension ChartboostDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: ChartboostParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        switch context.regulations.gdpr {
        case .doesNotApply:
            Chartboost.addDataUseConsent(CHBDataUseConsent.GDPR(CHBDataUseConsent.GDPR.Consent.nonBehavioral))
        case .applies:
            Chartboost.addDataUseConsent(CHBDataUseConsent.GDPR(CHBDataUseConsent.GDPR.Consent.behavioral))
        case .unknown:
            break
        }

        if context.regulations.usPrivacyString != nil {
            Chartboost.addDataUseConsent(CHBDataUseConsent.CCPA(CHBDataUseConsent.CCPA.Consent.optInSale))
        } else {
            Chartboost.addDataUseConsent(CHBDataUseConsent.CCPA(CHBDataUseConsent.CCPA.Consent.optOutSale))
        }

        Chartboost.start(
            withAppID: parameters.appId,
            appSignature: parameters.appSignature
        ) { [weak self] error in
            if let error {
                completion(SdkError(error.localizedDescription))
            } else {
                self?.isInitialized = true
                completion(nil)
            }
        }
    }
}
