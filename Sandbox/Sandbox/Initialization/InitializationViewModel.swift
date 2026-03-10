//
//  InitializationViewModel.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import Combine
import SwiftUI

import Bidon
import BidonAdapterAppLovin
import BidonAdapterBidMachine
import BidonAdapterGoogleMobileAds
import BidonAdapterGoogleAdManager
import BidonAdapterDTExchange
import BidonAdapterUnityAds
import BidonAdapterMintegral
import BidonAdapterMobileFuse
import BidonAdapterVungle
import BidonAdapterBigoAds
import BidonAdapterMetaAudienceNetwork
import BidonAdapterInMobi
import BidonAdapterAmazon
import BidonAdapterMyTarget
import BidonAdapterChartboost
import BidonAdapterIronSource
import BidonAdapterMoloco
import BidonAdapterStartIo
import BidonAdapterTaurusX
import BidonAdapterYandex

final class InitializationViewModel: ObservableObject, AdResponder {
    enum InitializationState {
        case idle
        case initializing
        case initialized
    }

    let permissions: [PermissionView.Model] = [
        AppTrackingTransparencyPermission(),
        LocationPermission()
    ].map { (permission: Permission) -> PermissionView.Model in
        PermissionView.Model(permission: permission)
    }

    @Published var hosts: [HostView.Model] = [
        .init(
            name: "Production",
            baseURL: Constants.Bidon.baseURL
        ),
        .init(
            name: "Staging 1",
            baseURL: Constants.Bidon.stagingFirstURL,
            user: Constants.Bidon.stagingUser,
            password: Constants.Bidon.stagingPassword
        ),
        .init(
            name: "Staging 2",
            baseURL: Constants.Bidon.stagingSecondURL,
            user: Constants.Bidon.stagingUser,
            password: Constants.Bidon.stagingPassword
        )
    ]

    @Published var initializationState: InitializationState = .idle

    @Published var logLevel: LogLevel = .debug {
        didSet { adService.parameters.logLevel = logLevel }
    }

    @Published var isTestMode: Bool = false {
        didSet { adService.parameters.isTestMode = isTestMode }
    }

    @Published var host = HostView.Model(
        name: "Production",
        baseURL: Constants.Bidon.baseURL
    ) {
        didSet {
            adService.bidonURL = host.baseURL

            let credentials = [host.user, host.password].compactMap { $0 }
            guard
                credentials.count == 2,
                let authorization = credentials
                    .joined(separator: ":")
                    .data(using: .utf8)?
                    .base64EncodedString()
            else {
                adService.bidonHTTPHeaders = [:]
                return
            }

            adService.bidonHTTPHeaders = ["Authorization": "Basic \(authorization)"]
        }
    }

    @Published var adapters: [Bidon.Adapter] = .default()

    @MainActor
    func initialize() async {
        let emptyConfig = AdTypeCacheConfig(adunitСacheSize: 5, fallbackСacheSize: 5, noFillDelayMs: 0, strategy: 1, threshold: 80)
        let interstitialConfig = AdTypeCacheConfig(adunitСacheSize: 5, fallbackСacheSize: 5, noFillDelayMs: 0, strategy: 1, threshold: 80)
        BidonSdk.setAdCacheConfig(AdCacheConfig(
            banner: emptyConfig,
            interstitial: interstitialConfig,
            rewardedVideo: emptyConfig)
        )
        update(.initializing)
        await adService.initialize()
        update(.initialized)
    }

    func registerDefaultAdapters() {
        BidonSdk.registerDefaultAdapters()
        withAnimation { [unowned self] in
            self.adapters = .default()
        }
    }

    private func update(
        _ state: InitializationState,
        animation: Animation = .default
    ) {
        withAnimation(animation) { [unowned self] in
            self.initializationState = state
        }
    }
}


fileprivate extension Array where Element == Bidon.Adapter {
    static func `default`() -> [Element] {
        return [
            ChartboostDemandSourceAdapter(),
            IronSourceDemandSourceAdapter(),
            MyTargetDemandSourceAdapter(),
            AppLovinDemandSourceAdapter(),
            BidMachineDemandSourceAdapter(),
            GoogleMobileAdsDemandSourceAdapter(),
            DTExchangeDemandSourceAdapter(),
            UnityAdsDemandSourceAdapter(),
            MintegralDemandSourceAdapter(),
            MobileFuseDemandSourceAdapter(),
            VungleDemandSourceAdapter(),
            BigoAdsDemandSourceAdapter(),
            MetaAudienceNetworkDemandSourceAdapter(),
            InMobiDemandSourceAdapter(),
            AmazonDemandSourceAdapter(),
            GoogleAdManagerDemandSourceAdapter(),
            StartIoDemandSourceAdapter(),
            MolocoDemandSourceAdapter(),
            TaurusXDemandSourceAdapter(),
            YandexDemandSourceAdapter()
        ].sorted { $0.demandId < $1.demandId }
    }
}
