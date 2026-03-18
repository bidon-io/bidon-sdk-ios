//
//  BannerAdDemoView.swift
//  Sandbox
//
//  Created by Евгения Григорович on 24/06/2025.
//

import Bidon
import UIKit
import SwiftUI

final class BannerAdController: NSObject, ObservableObject, AdViewDelegate {
    @Published var logs: [String] = []
    @Published var status: String = "Idle"
    @Published var isAdReady: Bool = false

    private let banner: BannerView = {
        let view = BannerView(frame: .zero, auctionKey: nil)
        view.format = .banner
        return view
    }()

    override init() {
        super.init()
        banner.delegate = self
        banner.autorefreshInterval = 0
        logs.append("Start")
    }

    func getBannerView() -> UIView {
        return banner
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
        logs.append("🎬 Loading banner ad")
        status = "Loading..."
        guard let vc = UIApplication.shared
        .connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: \.isKeyWindow)?
        .rootViewController else {
            logs.append("⚠️ No root view controller")
            return
        }
        banner.rootViewController = vc
        banner.loadAd()
    }

    // MARK: - AdViewDelegate

    func adObject(_ adObject: AdObject, didLoadAd ad: Ad, auctionInfo: AuctionInfo) {
        Logger.debug("[Banner] [Callback] Did load ad")
        logs.append("✅ Banner Loaded")
        status = "Ad Loaded"
        isAdReady = true
    }

    func adObject(_ adObject: AdObject, didFailToLoadAd error: any Error, auctionInfo: AuctionInfo) {
        Logger.debug("[Banner] [Callback] Did fail to load with error: \(error.localizedDescription)")
        logs.append("❌ Failed to load: \(error.localizedDescription)")
        status = "Failed"
        isAdReady = false
    }

    func adObject(_ adObject: AdObject, didFailToPresentAd error: any Error) {
        Logger.debug("[Banner] [Callback] Did fail to present with error: \(error.localizedDescription)")
        logs.append("❌ Failed to present: \(error.localizedDescription)")
    }

    func adObject(_ adObject: AdObject, didExpireAd ad: Ad) {
        Logger.debug("[Banner] [Callback] Did expire ad")
        logs.append("⏰ Ad expired")
        status = "Ad Expired"
        isAdReady = false
    }

    func adObject(_ adObject: AdObject, didRecordImpression ad: Ad) {
        Logger.debug("[Banner] [Callback] Did record impression")
        logs.append("👁 Impression recorded")
    }

    func adObject(_ adObject: AdObject, didRecordClick ad: Ad) {
        Logger.debug("[Banner] [Callback] Did record click")
        logs.append("👆 Click recorded")
    }

    func adObject(_ adObject: AdObject, didPay revenue: AdRevenue, ad: Ad) {
        Logger.debug("[Banner] [Callback] Did pay revenue: \(revenue.revenue)")
        logs.append("💰 Revenue: \(revenue.revenue)")
    }

    func adView(_ adView: any UIView & Bidon.AdView, willPresentScreen ad: any Bidon.Ad) {
        Logger.debug("[Banner] [Callback] Will present screen")
        logs.append("📲 Will present screen")
    }

    func adView(_ adView: any UIView & Bidon.AdView, didDismissScreen ad: any Bidon.Ad) {
        Logger.debug("[Banner] [Callback] Did dismiss screen")
        logs.append("👋 Screen dismissed")
    }

    func adView(_ adView: any UIView & Bidon.AdView, willLeaveApplication ad: any Bidon.Ad) {
        Logger.debug("[Banner] [Callback] Will leave application")
        logs.append("🚪 Will leave application")
    }
}

struct BannerAdDemoView: View {
    @StateObject private var controller = BannerAdController()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Banner Demo")
                    .font(.title2)
                    .bold()

                Button("Initialize SDK") {
                    controller.initializeSDK()
                }

                Button("Load Banner Ad") {
                    controller.loadAd()
                }

                Text("Status: \(controller.status)")
                    .padding(.top)

                BannerViewRepresentable(controller: controller)
                    .frame(width: 320, height: 50)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

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

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Banner Ad")
    }
}

struct BannerViewRepresentable: UIViewRepresentable {
    let controller: BannerAdController

    func makeUIView(context: Context) -> UIView {
        controller.getBannerView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
