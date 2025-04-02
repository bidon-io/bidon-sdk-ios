//
//  Defines.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 15.06.2022.
//

import Foundation


struct Constants {
    static let sdkVersion: String = "0.7.12"
  
    static let zeroUUID: String = "00000000-0000-0000-0000-000000000000"
    
    static let defaultPlacement: String = "default"
    
    enum API {
        static let host = "b.appbaqend.com"
        static let baseURL = "https://" + host
    }
    
    enum Adapters {
        static var classes: [String] = [
            "BidonAdapterAmazon.AmazonDemandSourceAdapter",
            "BidonAdapterBidMachine.BidMachineDemandSourceAdapter",
            "BidonAdapterGoogleMobileAds.GoogleMobileAdsDemandSourceAdapter",
            "BidonAdapterAppLovin.AppLovinDemandSourceAdapter",
            "BidonAdapterDTExchange.DTExchangeDemandSourceAdapter",
            "BidonAdapterUnityAds.UnityAdsDemandSourceAdapter",
            "BidonAdapterMintegral.MintegralDemandSourceAdapter",
            "BidonAdapterMobileFuse.MobileFuseDemandSourceAdapter",
            "BidonAdapterVungle.VungleDemandSourceAdapter",
            "BidonAdapterBigoAds.BigoAdsDemandSourceAdapter",
            "BidonAdapterMetaAudienceNetwork.MetaAudienceNetworkDemandSourceAdapter",
            "BidonAdapterInMobi.InMobiDemandSourceAdapter",
            "BidonAdapterAmazon.AmazonDemandSourceAdapter",
            "BidonAdapterGoogleAdManager.GoogleAdManagerDemandSourceAdapter",
            "BidonAdapterMyTarget.MyTargetDemandSourceAdapter",
            "BidonAdapterIronSource.IronSourceDemandSourceAdapter",
            "BidonAdapterYandex.YandexDemandSourceAdapter",
            "BidonAdapterChartboost.ChartboostDemandSourceAdapter"
        ]
    }
    
    enum UserDefaultsKey {
        static let token = "BidonToken"
        static let idg = "BidonIdg"
        static let coppa = "BidonCoppa"
        static let segmentId = "BidonSegmentId"
        static let segmentUid = "BidonSegmentUid"
    }
    
    enum Timeout {
        static let defaultTokensTimeout: TimeInterval = 10.0
        static let defaultAuctionTimeout: Float = 30.0
    }
}
