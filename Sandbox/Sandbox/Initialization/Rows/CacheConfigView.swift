//
//  CacheConfigView.swift
//  Sandbox
//
//  Created by Evgenia Gorbacheva on 14/11/2024.
//

import SwiftUI
import Bidon

class AdCacheConfigViewModel: ObservableObject {
    @Published var bannerConfig: AdTypeCacheConfig
    @Published var interstitialConfig: AdTypeCacheConfig
    @Published var rewardedVideoConfig: AdTypeCacheConfig

    init(
        banner: AdTypeCacheConfig = AdTypeCacheConfig(),
        interstitial: AdTypeCacheConfig = AdTypeCacheConfig(),
        rewardedVideo: AdTypeCacheConfig = AdTypeCacheConfig()
    ) {
        self.bannerConfig = banner
        self.interstitialConfig = interstitial
        self.rewardedVideoConfig = rewardedVideo
    }

    // Example action to reset configurations
    func resetToDefault() {
        bannerConfig = AdTypeCacheConfig()
        interstitialConfig = AdTypeCacheConfig()
        rewardedVideoConfig = AdTypeCacheConfig()
    }
}

struct AdCacheConfigView: View {
    @ObservedObject private var viewModel = AdCacheConfigViewModel()
    @Environment(\.presentationMode) private var presentationMode
    var onSave: ((AdCacheConfig) -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Banner Configuration")) {
                    AdTypeConfigView(config: $viewModel.bannerConfig)
                }
                Section(header: Text("Interstitial Configuration")) {
                    AdTypeConfigView(config: $viewModel.interstitialConfig)
                }
                Section(header: Text("Rewarded Video Configuration")) {
                    AdTypeConfigView(config: $viewModel.rewardedVideoConfig)
                }
                Button("Reset to Default") {
                    viewModel.resetToDefault()
                }
                .foregroundColor(.red)
                
                // Save Button
                Button("Save Configuration") {
                    onSave?(AdCacheConfig(banner: viewModel.bannerConfig, interstitial: viewModel.interstitialConfig, rewardedVideo: viewModel.rewardedVideoConfig)) // Pass the updated viewModel back
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Ad Cache Configuration")
        }
    }
}

struct AdTypeConfigView: View {
    @Binding var config: AdTypeCacheConfig
    let sortingStrategies = ["Timestamp", "eCPM"]

    var body: some View {
        Picker("Sort Strategy", selection: $config.sortStrategy) {
            ForEach([SortingStrategy.ecpm, SortingStrategy.timestamp], id: \.self) { strategy in
                Text(strategy.description).tag(strategy)
            }
        }

        Stepper("Ad Unit Cache Size: \(config.adunitСacheSize)", value: $config.adunitСacheSize, in: 1...100)
        
        // Updated Stepper for No Fill Delay with proper binding
        Stepper(value: $config.noFillDelayMs, in: 0...640000, step: 1000) {
            Text("No Fill Delay (ms): \(Int(config.noFillDelayMs))")
        }
    }
}

struct SavedConfigView: View {
    @ObservedObject var viewModel: AdCacheConfigViewModel

    var body: some View {
        Form {
            Section(header: Text("Saved Banner Configuration")) {
                Text("Sort Strategy: \(viewModel.bannerConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.bannerConfig.adunitСacheSize)")
                Text("No Fill Delay (ms): \(Int(viewModel.bannerConfig.noFillDelayMs))")
            }
            Section(header: Text("Saved Interstitial Configuration")) {
                Text("Sort Strategy: \(viewModel.interstitialConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.interstitialConfig.adunitСacheSize)")
                Text("No Fill Delay (ms): \(Int(viewModel.interstitialConfig.noFillDelayMs))")
            }
            Section(header: Text("Saved Rewarded Video Configuration")) {
                Text("Sort Strategy: \(viewModel.rewardedVideoConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.rewardedVideoConfig.adunitСacheSize)")
                Text("No Fill Delay (ms): \(Int(viewModel.rewardedVideoConfig.noFillDelayMs))")
            }
        }
        .navigationTitle("Saved Config")
    }
}

extension SortingStrategy: Identifiable {
    public var id: Int { self.rawValue }

    var description: String {
        switch self {
        case .timestamp: return "Timestamp"
        case .ecpm: return "eCPM"
        }
    }
}
