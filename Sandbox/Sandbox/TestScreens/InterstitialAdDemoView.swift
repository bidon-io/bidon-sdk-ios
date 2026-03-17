//
//  InterstitialAdDemoView.swift
//  Sandbox
//
//  Created by Евгения Григорович on 24/06/2025.
//


import SwiftUI
import UIKit
import Bidon

final class InterstitialAdController: NSObject, ObservableObject, FullscreenAdDelegate {
    @Published var logs: [String] = []
    @Published var status: String = "Idle"
    @Published var isAdReady: Bool = false

    let interstitial = Interstitial()

    override init() {
        super.init()
        interstitial.delegate = self
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
        logs.append("🎬 Loading interstitial")
        status = "Loading..."
        interstitial.loadAd()
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

        logs.append("📲 Showing interstitial")
        interstitial.showAd(from: vc)
    }

    // MARK: - FullscreenAdDelegate

    func adObject(_ adObject: AdObject, didLoadAd ad: Ad, auctionInfo: AuctionInfo) {
        Logger.debug("[Interstitial] [Callback] Did load ad")
        logs.append("✅ Ad Loaded")
        status = "Ad Loaded"
        isAdReady = true
    }

    func adObject(_ adObject: AdObject, didFailToLoadAd error: any Error, auctionInfo: AuctionInfo) {
        Logger.debug("[Interstitial] [Callback] Did fail to load with error: \(error.localizedDescription)")
        logs.append("❌ Failed to load: \(error.localizedDescription)")
        status = "Failed"
        isAdReady = false
    }

    func adObject(_ adObject: AdObject, didFailToPresentAd error: any Error) {
        Logger.debug("[Interstitial] [Callback] Did fail to present with error: \(error.localizedDescription)")
        logs.append("❌ Failed to present: \(error.localizedDescription)")
    }

    func adObject(_ adObject: AdObject, didExpireAd ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Did expire ad")
        logs.append("⏰ Ad expired")
        status = "Ad Expired"
        isAdReady = false
    }

    func adObject(_ adObject: AdObject, didRecordImpression ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Did record impression")
        logs.append("👁 Impression recorded")
    }

    func adObject(_ adObject: AdObject, didRecordClick ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Did record click")
        logs.append("👆 Click recorded")
    }

    func adObject(_ adObject: AdObject, didPay revenue: AdRevenue, ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Did pay revenue: \(revenue.revenue)")
        logs.append("💰 Revenue: \(revenue.revenue)")
    }

    func fullscreenAd(_ adObject: FullscreenAdObject, willPresentAd ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Will present ad")
        logs.append("📲 Will present ad")
        status = "Showing"
    }

    func fullscreenAd(_ adObject: FullscreenAdObject, didDismissAd ad: Ad) {
        Logger.debug("[Interstitial] [Callback] Did dismiss ad")
        logs.append("👋 Ad dismissed")
        status = "Dismissed"
        isAdReady = false
    }
}

struct InterstitialAdDemoView: View {
    @StateObject private var controller = InterstitialAdController()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Interstitial Demo")
                    .font(.title2)
                    .bold()

                Button("Initialize SDK") {
                    controller.initializeSDK()
                }

                Button("Load Interstitial Ad") {
                    controller.loadAd()
                }

                Button("Show Interstitial Ad") {
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
        .navigationTitle("Interstitial Ad")
    }
}
