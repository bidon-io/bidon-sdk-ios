//
//  AdvertisingServiceProvider.swift
//  Sandbox
//
//  Created by Bidon Team on 13.02.2023.
//

import Foundation
import UIKit
import Combine
import AppsFlyerLib
import Bidon
import FBSDKCoreKit
import FBSDKLoginKit


final class AdServiceProvider: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    static let shared = AdServiceProvider()

    var service: AdService = RawAdService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) {
        setupAppsFlyer()
        setupMeta(
            application: application,
            launchOptions: launchOptions
        )
    }

    private func setupAppsFlyer() {
        AppsFlyerLib.shared().appsFlyerDevKey = Constants.AppsFlyer.devKey
        AppsFlyerLib.shared().appleAppID = Constants.AppsFlyer.appId

        unowned let unownedSelf = self
        NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink(receiveValue: unownedSelf.receiveApplicationDidBecomeActive)
            .store(in: &cancellables)
    }

    private func setupMeta(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        Settings.shared.appID = Constants.Facebook.appId
        Settings.shared.clientToken = Constants.Facebook.clientToken

        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    private func receiveApplicationDidBecomeActive(notification: Notification) {
        AppsFlyerLib.shared().start()
    }
}

extension AppsFlyerLib {
    func log(
        adRevenue: AdRevenue,
        ad: Bidon.Ad,
        adType: Bidon.AdType,
        placement: String = ""
    ) {

        let adRevenueData = AFAdRevenueData(
            monetizationNetwork: ad.networkName,
            mediationNetwork: .appodeal,
            currencyIso4217Code: adRevenue.currency,
            eventRevenue: adRevenue.revenue as NSNumber
        )

        var additionalParameters: [String: Any] = [:]
        additionalParameters[kAppsFlyerAdRevenueAdType] = adType.rawValue
//        Should we remove this line?
//        additionalParameters[kAppsFlyerAdRevenueAdUnit] = ad.adUnitId
        additionalParameters[kAppsFlyerAdRevenuePlacement] = placement

        logAdRevenue(
            adRevenueData,
            additionalParameters: additionalParameters
        )
    }
}
