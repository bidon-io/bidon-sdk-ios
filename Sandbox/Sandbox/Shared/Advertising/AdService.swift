//
//  AdvertisingService.swift
//  Sandbox
//
//  Created by Bidon Team on 13.02.2023.
//

import Foundation
import Bidon
import Combine


enum Mediation: String, CaseIterable {
    case none
    case appodeal
}


enum AdType {
    case banner
    case interstitial
    case rewardedAd
}


enum LogLevel: String, CaseIterable {
    case verbose
    case debug
    case info
    case warning
    case error
    case off
}


enum Gender: String, CaseIterable {
    case male
    case female
    case other
}


protocol AdServiceParameters: AnyObject {
    var logLevel: LogLevel { get set }
    var isTestMode: Bool { get set }
    var userAge: Int? { get set }
    var coppaApplies: Bool? { get set }
    var gdprApplies: Bool? { get set }
    var gdprConsentString: String? { get set }
    var usPrivacyString: String? { get set }
    var gameLevel: Int? { get set }
    var userGender: Gender? { get set }
    var isPaidApp: Bool { get set }
    var inAppAmount: Double { get set }
    var extras: [String: AnyHashable] { get set }
    var customAttributes: [String: AnyHashable] { get set }
}


protocol AdService: AnyObject {
    var mediation: Mediation { get }
    var verstion: String { get }
    var segmentId: String? { get }
    var parameters: AdServiceParameters { get }

    func initialize() async

    func adEventPublisher(adType: AdType) -> AnyPublisher<AdEventModel, Never>

    func adPublisher(adType: AdType) -> AnyPublisher<Bidon.Ad?, Never>

    func load(pricefloor: Double, adType: AdType, auctionKey: String?) async throws

    func canShow(adType: AdType) -> Bool

    func show(adType: AdType) async throws

    func notify(loss ad: Ad, adType: AdType)

    func notify(win ad: Ad, adType: AdType)
}


protocol AdResponder {}


extension AdService {
    var bidonURL: String {
        get { BidonSdk.baseURL }
        set { BidonSdk.baseURL = newValue }
    }

    var bidonHTTPHeaders: [String: String] {
        get { BidonSdk.HTTPHeaders }
        set { BidonSdk.HTTPHeaders = newValue }
    }
}

extension AdResponder {
    var adService: AdService {
        AdServiceProvider.shared.service
    }
}
