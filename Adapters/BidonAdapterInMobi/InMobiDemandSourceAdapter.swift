//
//  InMobiDemandSourceAdapter.swift
//  BidonAdapterInMobi
//
//  Created by Stas Kochkin on 11.09.2023.
//

import Foundation
import Bidon
import InMobiSDK


internal typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc final public class InMobiDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "inmobi"
    
    public let demandId: String = InMobiDemandSourceAdapter.identifier
    public let name: String = "InMobi"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = IMSdk.getVersion()
    
    private(set) public var isInitialized: Bool = false
    
    @Injected(\.context)
    var context: SdkContext
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return InMobiInterstitialDemandProvider()
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return InMobiInterstitialDemandProvider()
    }
    
    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return InMobiAdViewDemandProvider(context: context)
    }
}


extension InMobiDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: InMobiParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        IMSdk.setLogLevel(.current)
        
        var consentDictionary: [String: Any] = [:]
        
        switch context.regulations.gdpr {
        case .applies:
            consentDictionary[IMCommonConstants.IM_GDPR_CONSENT_AVAILABLE] = "true"
        case .doesNotApply:
            consentDictionary[IMCommonConstants.IM_GDPR_CONSENT_AVAILABLE] = "false"
        default:
            break
        }
        
        if let gdprConsentString =  context.regulations.gdprConsentString {
            consentDictionary[IMCommonConstants.IM_GDPR_CONSENT_IAB] = gdprConsentString
        }
        
        IMSdk.initWithAccountID(
            parameters.accountId,
            consentDictionary: consentDictionary
        ) { [weak self] error in
            self?.isInitialized = error != nil
            completion(error.map(SdkError.generic))
        }
    }
}


extension IMSDKLogLevel {
    static var current: IMSDKLogLevel {
        switch Bidon.Logger.level {
        case .off: return .none
        case .error: return .error
        default: return .debug
        }
    }
}
