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
    static var adFormat: GoogleMobileAds.AdFormat { get }
    
    var paidEventHandler: GADPaidEventHandler? { get set }
}


extension GoogleMobileAds.InterstitialAd: GoogleAdManagerDemandAd {
    static var adFormat: GoogleMobileAds.AdFormat { .interstitial }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension GoogleMobileAds.RewardedAd: GoogleAdManagerDemandAd {
    static var adFormat: GoogleMobileAds.AdFormat { .rewarded }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
   
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension GoogleMobileAds.BannerView: GoogleAdManagerDemandAd {
    static var adFormat: GoogleMobileAds.AdFormat { .banner }
    
    public var id: String {
        responseInfo?.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo?.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}
