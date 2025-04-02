//
//  IronSourceBaseDemandProvider.swift
//  BidonAdapterIronSource
//
//  Created by Евгения Григорович on 12/08/2024.
//

import Foundation
import Bidon
import IronSource

typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter

@objc public final class IronSourceDemandSourceAdapter: NSObject, DemandSourceAdapter {
    
    @objc public static let identifier = "ironsource"
    
    public let demandId: String = IronSourceDemandSourceAdapter.identifier
    public let name: String = "IronSource"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = IronSource.sdkVersion()
    private(set) public var isInitialized = false
    
    let api: IronSourceApi = BaseIronSourceApi()
    let delegate = ImpressionDataDelegate()
    
    @Injected(\.context)
    var context: SdkContext
    
    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return IronSourceInterstitialDemandProvider(api: api)
    }
    
    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return IronSourceRewardedDemandProvider(api: api)
    }
    
    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return IronSourceAdViewDemandProvider(context: context, api: api)
    }
}


extension IronSourceDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: IronSourceParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        api.setConsent(context.regulations.gdpr == .applies)
        api.setChildDirected(context.regulations.coppa == .yes)
        
        api.addImpressionDataDelegate(delegate)
        api.initialiseIronSource(with: parameters.appKey)
        isInitialized = true
        
        completion(nil)
    }
}

final class ImpressionDataDelegate: NSObject, ISImpressionDataDelegate {
    
    public func impressionDataDidSucceed(_ impressionData: ISImpressionData!) {
        print(impressionData)
    }
}
