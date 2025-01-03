//
//  InitializationVIew.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import SwiftUI
import Bidon


struct InitializationView: View {
    @EnvironmentObject var vm: InitializationViewModel
    
    private var appVersion: String {
        let appVersion = Bundle.main.versionString("CFBundleShortVersionString")
        let buildVersion = Bundle.main.versionString("CFBundleVersion")
        
        return "\(appVersion)(\(buildVersion))"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                background
                content
                footer
                if vm.initializationState.isAnimating {
                    overlay
                }
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(.stack)
    }

    // MARK: - Components
    private var background: some View {
        Color(UIColor.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        VStack {
            List {
                demandSourceAdaptersSection
                baseURLSection
                permissionsSection
                settingsSection
            }
            .padding(.bottom, 200)
            .disabled(!vm.initializationState.isIdle)
            .listStyle(.insetGrouped)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading) {
            Spacer()
            VStack(spacing: 20) {
                initializeButton
                footerInfo
            }
            .padding(.vertical)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor)
                    .edgesIgnoringSafeArea(.bottom)
            )
        }
    }

    // MARK: - Sections
    private var demandSourceAdaptersSection: some View {
        Section(
            header: HStack {
                Text("Demand Source Adapters")
                Spacer()
                Button(action: vm.registerDefaultAdapters) {
                    Text("Register all")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .light))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
            }
        ) {
            AdaptersView(adapters: $vm.adapters)
        }
    }

    private var baseURLSection: some View {
        Section(header: Text("Base URL")) {
            HostView(
                hosts: $vm.hosts,
                selected: $vm.host
            )
        }
    }

    private var permissionsSection: some View {
        Section(header: Text("Permissions")) {
            ForEach(vm.permissions) {
                PermissionView($0)
            }
        }
    }

    private var settingsSection: some View {
        Section(header: Text("Settings")) {
            Toggle("Test Mode", isOn: $vm.isTestMode)
            NavigationLink(destination: AdServiceParametersView(vm.adService.parameters)) {
                Text("Advanced")
            }
            NavigationLink(destination: AdCacheConfigView(onSave: saveCacheConfig)) {
                Text("Cache Config")
            }
        }
    }

    // MARK: - Footer Components
    private var initializeButton: some View {
        Button(action: initialize) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(vm.initializationState.accentColor)
                Text(vm.initializationState.text)
                    .bold()
                    .foregroundColor(.accentColor)
            }
            .frame(height: 44)
        }
        .padding(.horizontal)
        .disabled(!vm.initializationState.isIdle)
    }

    private var footerInfo: some View {
        VStack(alignment: .leading) {
            Text("Mediation: ") + Text(AdServiceProvider().service.mediation.rawValue.capitalized + " v" + AdServiceProvider().service.verstion).bold()
            Text("Bidon SDK: ") + Text("v\(BidonSdk.sdkVersion)").bold()
            Text("Bundle ID: ") + Text(Bundle.main.bundleIdentifier ?? "").bold()
            Text("App Key: ") + Text(Constants.Bidon.appKey).bold()
            Text("App Version: ") + Text(appVersion).bold()
        }
        .lineLimit(1)
        .foregroundColor(.white)
        .font(.caption)
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var overlay: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.25)
                .transition(.scale.combined(with: .opacity))
            AppProgressView()
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Helper Methods
    private func saveCacheConfig(config: AdCacheConfig) {
        let banner = Bidon.AdTypeCacheConfig(
            adCacheEnabled: config.banner.adCacheEnabled,
            adunitСacheSize: config.banner.adunitCacheSize,
            noFillDelayMs: config.banner.noFillDelayMs
        )
        let inter = Bidon.AdTypeCacheConfig(
            adCacheEnabled: config.interstitial.adCacheEnabled,
            adunitСacheSize: config.interstitial.adunitCacheSize,
            noFillDelayMs: config.interstitial.noFillDelayMs
        )
        let rewarded = Bidon.AdTypeCacheConfig(
            adCacheEnabled: config.rewardedVideo.adCacheEnabled,
            adunitСacheSize: config.rewardedVideo.adunitCacheSize,
            noFillDelayMs: config.rewardedVideo.noFillDelayMs
        )
        let conf = Bidon.AdCacheConfig(banner: banner, interstitial: inter, rewardedVideo: rewarded)
        BidonSdk.setAdCacheConfig(conf)
    }

    
    private func initialize() {
        Task {
            await vm.initialize()
        }
    }
}


private extension Bundle {
    func versionString(_ key: String) -> String {
        return (object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}


private extension InitializationViewModel.InitializationState {
    var isAnimating: Bool {
        return self == .initializing
    }
    
    var isIdle: Bool {
        return self == .idle
    }
    
    var text: String {
        switch self {
        case .idle: return "Initialize"
        case .initializing: return "Initializing..."
        case .initialized: return "Initialized"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .idle: return Color.white
        case .initializing: return Color.gray
        case .initialized: return Color.green
        }
    }
}
