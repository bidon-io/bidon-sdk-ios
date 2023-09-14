//
//  Bid.swift
//  Bidon
//
//  Created by Bidon Team on 29.03.2023.
//

import Foundation


enum DemandType {
    case bidding
    case programmatic
    case direct(LineItem)
}


protocol Bid: Hashable {
    associatedtype Provider
    
    var id: String { get }
    var adType: AdType { get }
    var demandType: DemandType { get }
    var eCPM: Price { get }
    var ad: DemandAd { get }
    var provider: Provider { get }
    var roundConfiguration: AuctionRoundConfiguration { get }
    var auctionConfiguration: AuctionConfiguration { get }
}


extension DemandType {
    var lineItem: LineItem? {
        switch self {
        case .direct(let lineItem): return lineItem
        default: return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .bidding: return "rtb"
        default: return "cpm"
        }
    }
}


struct BidModel<DemandProviderType>: Bid {
    var id: String
    var adType: AdType
    var eCPM: Price
    var demandType: DemandType
    var ad: DemandAd
    var provider: DemandProviderType
    var roundConfiguration: AuctionRoundConfiguration
    var auctionConfiguration: AuctionConfiguration
    
    static func == (
        lhs: BidModel<DemandProviderType>,
        rhs: BidModel<DemandProviderType>
    ) -> Bool {
        return lhs.ad.id == rhs.ad.id &&
        lhs.auctionConfiguration.auctionId == rhs.auctionConfiguration.auctionId &&
        lhs.roundConfiguration.roundId == rhs.roundConfiguration.roundId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ad.id)
        hasher.combine(auctionConfiguration.auctionId)
        hasher.combine(roundConfiguration.roundId)
    }
}


typealias AdViewBid = BidModel<any AdViewDemandProvider>
typealias InterstitialBid = BidModel<any InterstitialDemandProvider>
typealias RewardedAdBid = BidModel<any RewardedAdDemandProvider>


typealias AnyAdViewBid = BidModel<AnyAdViewDemandProvider>
typealias AnyInterstitialBid = BidModel<AnyInterstitialDemandProvider>
typealias AnyRewardedAdBid = BidModel<AnyRewardedAdDemandProvider>


extension AnyAdViewBid {
    func unwrapped() -> AdViewBid {
        return AdViewBid(
            id: id,
            adType: adType,
            eCPM: eCPM,
            demandType: demandType,
            ad: ad,
            provider: provider.wrapped,
            roundConfiguration: roundConfiguration,
            auctionConfiguration: auctionConfiguration
        )
    }
}


extension AnyInterstitialBid {
    func unwrapped() -> InterstitialBid {
        return InterstitialBid(
            id: id,
            adType: adType,
            eCPM: eCPM,
            demandType: demandType,
            ad: ad,
            provider: provider.wrapped,
            roundConfiguration: roundConfiguration,
            auctionConfiguration: auctionConfiguration
        )
    }
}


extension AnyRewardedAdBid {
    func unwrapped() -> RewardedAdBid {
        return RewardedAdBid(
            id: id,
            adType: adType,
            eCPM: eCPM,
            demandType: demandType,
            ad: ad,
            provider: provider.wrapped,
            roundConfiguration: roundConfiguration,
            auctionConfiguration: auctionConfiguration
        )
    }
}
