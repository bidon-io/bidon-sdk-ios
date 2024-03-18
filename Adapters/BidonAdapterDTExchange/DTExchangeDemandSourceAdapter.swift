//
//  DTExchangeDemandSourceAdapter.swift
//  BidonAdapterDTExchange
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import IASDKCore
import Bidon


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class DTExchangeDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "dtexchange"
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    public let identifier: String = DTExchangeDemandSourceAdapter.identifier
    public let name: String = "DT Exchange"
    public let adapterVersion: String = "4"
    public let sdkVersion: String = IASDKCore.sharedInstance().version()
    
    private lazy var impressionObserver = DTExchangeDefaultImpressionObserver()
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return DTExchangeInterstitialDemandProvider(observer: impressionObserver)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return DTExchangeInterstitialDemandProvider(observer: impressionObserver)
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return DTExchangeBannerDemandProvider(observer: impressionObserver)
    }
}


extension DTExchangeDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        public var appId: String
    }
    
    public var isInitialized: Bool {
        return IASDKCore.sharedInstance().isInitialised
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        IASDKCore.sharedInstance().gdprConsent = IAGDPRConsentType(context.regulations.gdrpConsent)
        IASDKCore.sharedInstance().gdprConsentString = context.regulations.gdprConsentString
        IASDKCore.sharedInstance().ccpaString = context.regulations.usPrivacyString
        IASDKCore.sharedInstance().coppaApplies = IACoppaAppliesType(context.regulations.coppaApplies)
        IASDKCore.sharedInstance().initWithAppID(
            parameters.appId,
            completionBlock: { [weak self] isSuccess, error in
                defer { IASDKCore.sharedInstance().globalAdDelegate = self?.impressionObserver }
                
                if isSuccess {
                    completion(nil)
                } else if let error = error {
                    completion(.generic(error: error))
                } else {
                    completion(.unknown)
                }
            },
            completionQueue: nil
        )
    }
}


extension IAGDPRConsentType {
    init(_ status: Bidon.GDPRConsentStatus) {
        switch status {
        case .unknown: self = .unknown
        case .denied: self = .denied
        case .given: self = .given
        }
    }
}


extension IACoppaAppliesType {
    init(_ status: Bidon.COPPAAppliesStatus) {
        switch status {
        case .unknown: self = .unknown
        case .yes: self = .given
        case .no: self = .denied
        }
    }
}
