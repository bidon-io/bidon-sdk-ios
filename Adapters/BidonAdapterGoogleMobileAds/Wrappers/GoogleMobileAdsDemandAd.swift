//
//  GoogleMobileAd.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Bidon Team on 30.08.2022.
//

import Foundation
import GoogleMobileAds
import Bidon


protocol GoogleMobileAdsDemandAd: DemandAd {
    static var adFormat: AdFormat { get }
    
    var paidEventHandler: GADPaidEventHandler? { get set }
}


extension InterstitialAd: GoogleMobileAdsDemandAd {
    static var adFormat: AdFormat { .interstitial }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }

    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleMobileAdsDemandSourceAdapter.identifier
    }
}


extension GoogleMobileAds.RewardedAd: GoogleMobileAdsDemandAd {
    static var adFormat: AdFormat { .rewarded }
    
    public var id: String {
        responseInfo.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleMobileAdsDemandSourceAdapter.identifier
    }
}


extension GoogleMobileAds.BannerView: GoogleMobileAdsDemandAd {
    static var adFormat: AdFormat { .banner }
    
    public var id: String {
        responseInfo?.responseIdentifier ??
        String(hash)
    }
    
    public var networkName: String {
        responseInfo?.loadedAdNetworkResponseInfo?.adSourceName ??
        GoogleMobileAdsDemandSourceAdapter.identifier
    }
}
