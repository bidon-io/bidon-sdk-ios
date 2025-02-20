//
//  GoogleAdManagerDemandAd.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import Bidon
import GoogleMobileAds


protocol GoogleAdManagerDemandAd: DemandAd {
    static var adFormat: AdFormat { get }
    
    var paidEventHandler: GADPaidEventHandler? { get set }
}


extension AdManagerInterstitialAd: @retroactive DemandAd {}
extension AdManagerInterstitialAd: GoogleAdManagerDemandAd {
    static var adFormat: AdFormat { .interstitial }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension GoogleMobileAds.RewardedAd: @retroactive DemandAd {}
extension GoogleMobileAds.RewardedAd: GoogleAdManagerDemandAd {
    static var adFormat: AdFormat { .rewarded }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
   
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension AdManagerBannerView: GoogleAdManagerDemandAd {
    static var adFormat: AdFormat { .banner }
    
    public var id: String {
        responseInfo?.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo?.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}
