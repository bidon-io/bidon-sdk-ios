//
//  RawAdService.swift
//  Sandbox
//
//  Created by Bidon Team on 16.02.2023.
//

import Foundation
import Combine
import Bidon


enum RawAdServiceError: Error {
    case unsupported
    case noFill
    case invalidPresentationState
}


final class RawAdService: NSObject, AdService {
    var verstion: String { "-" }

    var segmentId: String?

    var parameters: AdServiceParameters = RawAdServiceParameters()

    private var interstitials: [String: RawInterstitialAdWrapper] = [:]
    private lazy var rewardedAd = RawRewardedAdWrapper()

    private func interstitial(for auctionKey: String?) -> RawInterstitialAdWrapper {
        let key = auctionKey ?? "default"
        if let existing = interstitials[key] { return existing }
        let wrapper = RawInterstitialAdWrapper()
        interstitials[key] = wrapper
        return wrapper
    }

    override init() {
        super.init()

        BidonSdk.logLevel = Bidon.Logger.Level(.debug)
    }

    func initialize() async {
        await withCheckedContinuation { continuation in
            BidonSdk.initialize(appKey: Constants.Bidon.appKey) {
                continuation.resume()
            }
        }
    }

    func adEventPublisher(adType: AdType, auctionKey: String?) -> AnyPublisher<AdEventModel, Never> {
        switch adType {
        case .interstitial:
            return interstitial(for: auctionKey).adEventSubject.eraseToAnyPublisher()
        case .rewardedAd:
            return rewardedAd.adEventSubject.eraseToAnyPublisher()
        default:
            fatalError("Not implemented")
        }
    }

    func adPublisher(adType: AdType, auctionKey: String?) -> AnyPublisher<Bidon.Ad?, Never> {
        switch adType {
        case .interstitial:
            return interstitial(for: auctionKey).adSubject.eraseToAnyPublisher()
        case .rewardedAd:
            return rewardedAd.adSubject.eraseToAnyPublisher()
        default:
            fatalError("Not implemented")
        }
    }

    func load(pricefloor: Double, adType: AdType, auctionKey: String?) async throws {
        switch adType {
        case .interstitial:
            try await interstitial(for: auctionKey).load(pricefloor: pricefloor, auctionKey: auctionKey)
        case .rewardedAd:
            try await rewardedAd.load(pricefloor: pricefloor, auctionKey: auctionKey)
        default:
            throw RawAdServiceError.unsupported
        }
    }

    func canShow(adType: AdType, auctionKey: String?) -> Bool {
        switch adType {
        case .interstitial:
            return interstitial(for: auctionKey).isReady
        case .rewardedAd:
            return rewardedAd.isReady
        default:
            return false
        }
    }

    func show(adType: AdType, auctionKey: String?) async throws {
        switch adType {
        case .interstitial:
            try await interstitial(for: auctionKey).show()
        case .rewardedAd:
            try await rewardedAd.show()
        default:
            throw RawAdServiceError.unsupported
        }
    }

    func notify(
        loss ad: Ad,
        adType: AdType
    ) {
        switch adType {
        case .interstitial:
            interstitials.values.forEach { $0.notify(loss: ad) }
        case .rewardedAd:
            rewardedAd.notify(loss: ad)
        default:
            break
        }
    }

    func notify(
        win ad: Ad,
        adType: AdType
    ) {
        switch adType {
        case .interstitial:
            interstitials.values.forEach { $0.notify(win: ad) }
        case .rewardedAd:
            rewardedAd.notify(win: ad)
        default:
            break
        }
    }
}
