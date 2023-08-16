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
    static var adFormat: GADAdFormat { get }
    
    var paidEventHandler: GADPaidEventHandler? { get set }
}


extension GADInterstitialAd: GoogleMobileAdsDemandAd {
    static var adFormat: GADAdFormat { .interstitial }
    
    public var id: String { responseInfo.responseIdentifier ?? UUID().uuidString }
    public var dsp: String? { nil }
    public var networkName: String { GoogleMobileAdsDemandSourceAdapter.identifier }
}


extension GADRewardedAd: GoogleMobileAdsDemandAd {
    static var adFormat: GADAdFormat { .rewarded }
    
    public var id: String { responseInfo.responseIdentifier ?? UUID().uuidString }
    public var dsp: String? { nil }
    public var networkName: String { GoogleMobileAdsDemandSourceAdapter.identifier }
}


extension GADBannerView: GoogleMobileAdsDemandAd {
    static var adFormat: GADAdFormat { .banner }
    
    public var id: String { responseInfo?.responseIdentifier ?? UUID().uuidString }
    public var dsp: String? { nil }
    public var networkName: String { GoogleMobileAdsDemandSourceAdapter.identifier }
}
