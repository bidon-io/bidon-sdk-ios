//
//  InitializationViewModel.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import Combine
import Bidon
import BidonAdapterAppLovin
import BidonAdapterBidMachine
import BidonAdapterGoogleMobileAds
import BidonAdapterDTExchange
import BidonAdapterUnityAds
import BidonAdapterMintegral
import BidonAdapterMobileFuse
import BidonAdapterVungle
import BidonAdapterBigoAds
import BidonAdapterMetaAudienceNetwork
import BidonAdapterInMobi
import BidonAdapterAmazon
import SwiftUI


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
        didSet { adService.bidonURL = host.baseURL }
    }
    
    @Published var mediation: Mediation = .none {
        didSet {
            switch mediation {
            case .none:
                AdServiceProvider.shared.service = RawAdService()
            case .appodeal:
                AdServiceProvider.shared.service = AppodealAdService()
            }
        }
    }
    
    @Published var adapters: [Bidon.Adapter] = .default()
    
    @MainActor
    func initialize() async {
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
            AmazonDemandSourceAdapter()
        ].sorted { $0.identifier < $1.identifier }
    }
}
