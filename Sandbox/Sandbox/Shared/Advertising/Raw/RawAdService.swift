//
//  RawAdService.swift
//  Sandbox
//
//  Created by Bidon Team on 16.02.2023.
//

import Foundation
import Foundation
import Combine
import Bidon


enum RawAdServiceError: Error {
    case unsupported
    case noFill
    case invalidPresentationState
}


final class RawAdService: NSObject, AdService {
    var mediation: Mediation { .none }
    
    var verstion: String { "-" }
    
    var segmentId: String?
    
    var parameters: AdServiceParameters = RawAdServiceParameters()
    
    private lazy var interstitial = RawInterstitialAdWrapper()
    private lazy var rewardedAd = RawRewardedAdWrapper()
    
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
    
    func adEventPublisher(adType: AdType) -> AnyPublisher<AdEventModel, Never> {
        switch adType {
        case .interstitial:
            return interstitial.adEventSubject.eraseToAnyPublisher()
        case .rewardedAd:
            return rewardedAd.adEventSubject.eraseToAnyPublisher()
        default:
            fatalError("Not implemented")
        }
    }
    
    func adPublisher(adType: AdType) -> AnyPublisher<Bidon.Ad?, Never> {
        switch adType {
        case .interstitial:
            return interstitial.adSubject.eraseToAnyPublisher()
        case .rewardedAd:
            return rewardedAd.adSubject.eraseToAnyPublisher()
        default:
            fatalError("Not implemented")
        }
    }
    
    func load(pricefloor: Double, adType: AdType, auctionKey: String?) async throws {
        switch adType {
        case .interstitial:
            try await interstitial.load(pricefloor: pricefloor, auctionKey: auctionKey)
        case .rewardedAd:
            try await rewardedAd.load(pricefloor: pricefloor, auctionKey: auctionKey)
        default:
            throw RawAdServiceError.unsupported
        }
    }
    
    func canShow(adType: AdType) -> Bool {
        switch adType {
        case .interstitial:
            return interstitial.isReady
        case .rewardedAd:
            return rewardedAd.isReady
        default:
            return false
        }
    }
    
    func show(adType: AdType) async throws {
        switch adType {
        case .interstitial:
            try await interstitial.show()
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
            interstitial.notify(loss: ad)
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
            interstitial.notify(win: ad)
        case .rewardedAd:
            rewardedAd.notify(win: ad)
        default:
            break
        }
    }
}

