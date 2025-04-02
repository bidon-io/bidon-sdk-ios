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
    static var adFormat: GADAdFormat { get }
    
    var paidEventHandler: GADPaidEventHandler? { get set }
}


extension GAMInterstitialAd: GoogleAdManagerDemandAd {
    static var adFormat: GADAdFormat { .interstitial }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension GADRewardedAd: GoogleAdManagerDemandAd {
    static var adFormat: GADAdFormat { .rewarded }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
   
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}


extension GAMBannerView: GoogleAdManagerDemandAd {
    static var adFormat: GADAdFormat { .banner }
    
    public var id: String {
        responseInfo?.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo?.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleAdManagerDemandSourceAdapter.identifier
    }
}
