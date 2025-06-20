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

    private(set) lazy var provider: BannerProvider = {
        let provider = BannerProvider(auctionKey: nil)
        provider.delegate = self
        return provider
    }()

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
        print("[Banner Provider Reference] Did load ad \(ad)")

        Logger.debug("[Public API] [AUCTION] [LOAD]: \(auctionInfo.description ?? "")")

        Logger.debug("[Public API] [AD] [LOAD]: \(ad.description() ?? "")")

        withAnimation { [unowned self] in
            self.isLoaded = true
        }
    }

    func adObject(_ adObject: AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        print("[Banner Provider Reference] Did fail to load ad with error: \(error)")

        Logger.debug("[Public API] [AUCTION] [LOAD] [ERROR]: \(auctionInfo.description ?? ""), error: \(error)")

        withAnimation { [unowned self] in
            self.isLoaded = false
        }
    }

    func adObject(_ adObject: AdObject, didFailToPresentAd error: Error) {
        print("[Banner Provider Reference] Did fail to present ad with error: \(error)")

        withAnimation { [unowned self] in
            self.isShown = false
        }
    }

    func adObject(_ adObject: AdObject, didRecordImpression ad: Ad) {
        print("[Banner Provider Reference] Did record impression for ad \(ad)")

        Logger.debug("[Public API] [AD] [SHOW]: \(ad.description() ?? "")")

        withAnimation { [unowned self] in
            self.isShown = true
        }
    }

    func adObject(_ adObject: AdObject, didExpireAd ad: Ad) {
        print("[Banner Provider Reference] Did expire ad \(ad)")
    }

    func adObject(_ adObject: AdObject, didRecordClick ad: Ad) {
        print("[Banner Provider Reference] Did record click for ad \(ad)")
    }

    func adObject(_ adObject: AdObject, didPay revenue: AdRevenue, ad: Ad) {
        Logger.debug("[Public API] [AD] [REVENUE]: \(ad.description(with: revenue) ?? "")")

        print("[Banner Provider Reference] Did pay revenue \(revenue) for ad \(ad)")
    }
}
