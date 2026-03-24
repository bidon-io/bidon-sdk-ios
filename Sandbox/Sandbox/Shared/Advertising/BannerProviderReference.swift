//
//  BannerProviderReference.swift
//  Sandbox
//
//  Created by Stas Kochkin on 06.09.2023.
//

import Foundation
import Bidon
import SwiftUI


final class BannerProviderReference: NSObject, AdObjectDelegate, ObservableObject {
    enum PositioningStyle: String {
        case fixed
        case custom
    }

    static let shared = BannerProviderReference()

    @Published var format: BannerFormat = .banner {
        didSet {
            provider.format = format
        }
    }

    @Published var positioningStyle = PositioningStyle.fixed {
        didSet { updatePosition() }
    }

    @Published var fixedPosition: BannerPosition? {
        didSet { updatePosition() }
    }

    @Published var customPosition: CGPoint? {
        didSet { updatePosition() }
    }

    @Published var customRotationAngle: CGFloat = 0.0 {
        didSet { updatePosition() }
    }

    @Published var customAnchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet { updatePosition() }
    }

    @Published var isShown: Bool = false
    @Published var isLoaded: Bool = false
    @Published var events: [AdEventModel] = []

    private(set) lazy var provider: BannerProvider = {
        let provider = BannerProvider(auctionKey: nil)
        provider.delegate = self
        return provider
    }()

    private func send(event title: String, detail: String, bage: String, color: Color) {
        let event = AdEventModel(
            date: Date(),
            adType: .banner,
            title: title,
            subtitle: detail,
            bage: bage,
            color: color
        )
        withAnimation { [unowned self] in
            self.events.append(event)
        }
    }

    func updatePosition() {
        switch positioningStyle {
        case .custom:
            provider.setCustomPosition(
                customPosition ?? .zero,
                rotationAngleDegrees: customRotationAngle,
                anchorPoint: customAnchorPoint
            )
        case .fixed:
            provider.setFixedPosition(fixedPosition ?? .horizontalBottom)
        }
    }

    func adObject(_ adObject: AdObject, didLoadAd ad: Ad, auctionInfo: AuctionInfo) {
        Logger.debug("[Banner] [Callback] Did load ad")
        Logger.debug("[Public API] [AUCTION] [LOAD]: \(auctionInfo.description ?? "")")
        Logger.debug("[Public API] [AD] [LOAD]: \(ad.description() ?? "")")
        send(event: "Bidon did load ad", detail: ad.text, bage: "star.fill", color: .accentColor)
        withAnimation { [unowned self] in
            self.isLoaded = true
        }
    }

    func adObject(_ adObject: AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        Logger.debug("[Banner] [Callback] Did fail to load ad with error: \(error.localizedDescription)")
        Logger.debug("[Public API] [AUCTION] [LOAD] [ERROR]: \(auctionInfo.description ?? ""), error: \(error)")
        send(event: "Bidon did fail to load ad", detail: error.localizedDescription, bage: "star.fill", color: .red)
        withAnimation { [unowned self] in
            self.isLoaded = false
        }
    }

    func adObject(_ adObject: AdObject, didFailToPresentAd error: Error) {
        Logger.debug("[Banner] [Callback] Did fail to present ad with error: \(error.localizedDescription)")
        send(event: "Bidon did fail to present ad", detail: error.localizedDescription, bage: "star.fill", color: .red)
        withAnimation { [unowned self] in
            self.isShown = false
        }
    }

    func adObject(_ adObject: AdObject, didRecordImpression ad: Ad) {
        Logger.debug("[Banner] [Callback] Did record impression")
        Logger.debug("[Public API] [AD] [SHOW]: \(ad.description() ?? "")")
        send(event: "Bidon did record impression", detail: ad.text, bage: "flag.fill", color: .accentColor)
        withAnimation { [unowned self] in
            self.isShown = true
        }
    }

    func adObject(_ adObject: AdObject, didExpireAd ad: Ad) {
        Logger.debug("[Banner] [Callback] Did expire ad")
        send(event: "Bidon expire ad", detail: ad.text, bage: "star.fill", color: .secondary)
        withAnimation { [unowned self] in
            self.isLoaded = false
        }
    }

    func adObject(_ adObject: AdObject, didRecordClick ad: Ad) {
        Logger.debug("[Banner] [Callback] Did record click")
        send(event: "Bidon did record click", detail: ad.text, bage: "flag.fill", color: .accentColor)
    }

    func adObject(_ adObject: AdObject, didPay revenue: AdRevenue, ad: Ad) {
        Logger.debug("[Banner] [Callback] Did pay revenue: \(revenue.revenue.pretty)")
        Logger.debug("[Public API] [AD] [REVENUE]: \(ad.description(with: revenue) ?? "")")
        send(event: "Bidon did pay revenue \(revenue.revenue.pretty)", detail: ad.text, bage: "cart.fill", color: .primary)
    }
}
