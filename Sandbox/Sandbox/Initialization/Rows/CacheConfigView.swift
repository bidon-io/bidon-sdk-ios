//
//  CacheConfigView.swift
//  Sandbox
//
//  Created by Evgenia Gorbacheva on 14/11/2024.
//

import SwiftUI

final class AdCacheConfig: ObservableObject {
    @Published var banner: AdTypeCacheConfig
    @Published var interstitial: AdTypeCacheConfig
    @Published var rewardedVideo: AdTypeCacheConfig
    
    init(
        banner: AdTypeCacheConfig = AdTypeCacheConfig(),
        interstitial: AdTypeCacheConfig = AdTypeCacheConfig(),
        rewardedVideo: AdTypeCacheConfig = AdTypeCacheConfig()
    ) {
        self.banner = banner
        self.interstitial = interstitial
        self.rewardedVideo = rewardedVideo
    }
    
    var description: String {
        "Banner: \(banner.description), Interstitial: \(interstitial.description), Rewarded: \(rewardedVideo.description)"
    }
}

final class AdTypeCacheConfig: ObservableObject {
    @Published var sortStrategy: SortingStrategy
    @Published var adunitCacheSize: Int
    @Published var noFillDelayMs: Int

    private let minCacheSize = 1
    private let maxCacheSize = 10

    private let minNoFillDelay = 2000
    private let maxNoFillDelay = 64000
    
    init(sortStrategy: SortingStrategy = .timestamp, adunitCacheSize: Int = 1, noFillDelayMs: Int = 2000) {
        self.sortStrategy = sortStrategy
        self.adunitCacheSize = max(minCacheSize, min(adunitCacheSize, maxCacheSize))
        self.noFillDelayMs = max(minNoFillDelay, min(noFillDelayMs, maxNoFillDelay))
    }
    
    var description: String {
        "size - \(adunitCacheSize), sort by \(sortStrategy.stringValue), delay - \(noFillDelayMs)"
    }
}

enum SortingStrategy: Int, Hashable, CaseIterable {
    case timestamp = 1
    case ecpm
    
    var stringValue: String {
        switch self {
        case .timestamp:
            return "timestamp"
        case .ecpm:
            return "ecpm"
        }
    }
}

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
                    AdTypeConfigView(config: viewModel.bannerConfig)
                }
                Section(header: Text("Interstitial Configuration")) {
                    AdTypeConfigView(config: viewModel.interstitialConfig)
                }
                Section(header: Text("Rewarded Video Configuration")) {
                    AdTypeConfigView(config: viewModel.rewardedVideoConfig)
                }
                
                Button("Reset to Default") {
                    viewModel.resetToDefault()
                }
                .foregroundColor(.red)
                
                Button("Save Configuration") {
                    onSave?(
                        AdCacheConfig(
                            banner: viewModel.bannerConfig,
                            interstitial: viewModel.interstitialConfig,
                            rewardedVideo: viewModel.rewardedVideoConfig
                        )
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Ad Cache Configuration")
        }
    }
}


struct AdTypeConfigView: View {
    @ObservedObject var config: AdTypeCacheConfig
    let sortingStrategies = SortingStrategy.allCases

    var body: some View {
        VStack {
            Picker("Sort Strategy", selection: $config.sortStrategy) {
                ForEach(sortingStrategies, id: \.self) { strategy in
                    Text(strategy.stringValue).tag(strategy)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Stepper("Ad Unit Cache Size: \(config.adunitCacheSize)", value: $config.adunitCacheSize, in: 1...10)
            
            Stepper(value: $config.noFillDelayMs, in: 2000...64000, step: 1000) {
                Text("No Fill Delay (ms): \(config.noFillDelayMs)")
            }
        }
        .padding()
    }
}


struct SavedConfigView: View {
    @ObservedObject var viewModel: AdCacheConfigViewModel

    var body: some View {
        Form {
            Section(header: Text("Saved Banner Configuration")) {
                Text("Sort Strategy: \(viewModel.bannerConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.bannerConfig.adunitCacheSize)")
                Text("No Fill Delay (ms): \(Int(viewModel.bannerConfig.noFillDelayMs))")
            }
            Section(header: Text("Saved Interstitial Configuration")) {
                Text("Sort Strategy: \(viewModel.interstitialConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.interstitialConfig.adunitCacheSize)")
                Text("No Fill Delay (ms): \(Int(viewModel.interstitialConfig.noFillDelayMs))")
            }
            Section(header: Text("Saved Rewarded Video Configuration")) {
                Text("Sort Strategy: \(viewModel.rewardedVideoConfig.sortStrategy.description)")
                Text("Ad Unit Cache Size: \(viewModel.rewardedVideoConfig.adunitCacheSize)")
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
