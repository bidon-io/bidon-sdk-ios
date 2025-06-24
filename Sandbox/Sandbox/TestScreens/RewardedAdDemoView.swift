//
//  RewardedAdDemoView.swift
//  Sandbox
//
//  Created by Евгения Григорович on 24/06/2025.
//

import SwiftUI
import UIKit
import Bidon

final class RewardedAdController: NSObject, ObservableObject, FullscreenAdDelegate, RewardedAdDelegate {
    @Published var logs: [String] = []
    @Published var status: String = "Idle"
    @Published var isAdReady: Bool = false

    let rewarded = RewardedAd()

    override init() {
        super.init()
        rewarded.delegate = self
        logs.append("Start")
    }

    func initializeSDK() {
        logs.append("ℹ️ Initializing SDK")
        BidonSdk.registerDefaultAdapters()
        BidonSdk.initialize(appKey: Constants.Bidon.appKey) {
            self.logs.append("✅ SDK Initialized")
            self.status = "SDK Initialized"
        }
    }

    func loadAd() {
        logs.append("🎬 Loading rewarded")
        status = "Loading..."
        rewarded.loadAd()
    }

    func showAd() {
        guard let vc = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                logs.append("⚠️ No root view controller")
                return
            }

        logs.append("📲 Showing rewarded")
        rewarded.showAd(from: vc)
    }

    // MARK: - FullscreenAdDelegate

    func adObject(_ adObject: AdObject, didLoadAd ad: Ad, auctionInfo: AuctionInfo) {
        logs.append("✅ Ad Loaded")
        status = "Ad Loaded"
        isAdReady = true
    }

    func adObject(_ adObject: AdObject, didFailToLoadAd error: any Error, auctionInfo: AuctionInfo) {
        logs.append("❌ Failed to load: \(error.localizedDescription)")
        status = "Failed"
    }

    func fullscreenAd(_ adObject: FullscreenAdObject, willPresentAd ad: Ad) {
        logs.append("📲 Will present ad")
        status = "Showing"
    }

    func fullscreenAd(_ adObject: FullscreenAdObject, didDismissAd ad: Ad) {
        logs.append("👋 Ad dismissed")
        status = "Dismissed"
        isAdReady = false
    }

    func rewardedAd(_ rewardedAd: any Bidon.RewardedAdObject, didRewardUser reward: any Bidon.Reward, ad: any Bidon.Ad) {
        logs.append("👋 Reward granted")
        status = "Reward"
        isAdReady = false
    }
}

struct RewardedAdDemoView: View {
    @StateObject private var controller = RewardedAdController()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Rewarded Demo")
                    .font(.title2)
                    .bold()

                Button("Initialize SDK") {
                    controller.initializeSDK()
                }

                Button("Load Rewarded Ad") {
                    controller.loadAd()
                }

                Button("Show Rewarded Ad") {
                    controller.showAd()
                }
                .disabled(!controller.isAdReady)

                Text("Status: \(controller.status)")
                    .padding(.top)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(controller.logs.indices, id: \.self) { index in
                            Text(controller.logs[index])
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
                .padding()

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Rewarded Ad")
    }
}
