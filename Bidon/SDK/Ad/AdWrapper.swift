//
//  AdWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


final class AdContainer: NSObject, Ad {
    final class AdNetworkUnitModel: NSObject, AdNetworkUnit {
        let uid: String
        let demandId: String
        let label: String
        let pricefloor: Price
        let bidType: AdBidType
        
        init(
            uid: String,
            demandId: String,
            label: String,
            pricefloor: Price,
            bidType: AdBidType
        ) {
            self.uid = uid
            self.demandId = demandId
            self.pricefloor = pricefloor
            self.label = label
            self.bidType = bidType
            super.init()
        }
        
        convenience init(_ adUnit: AnyAdUnit) {
            self.init(
                uid: adUnit.uid,
                demandId: adUnit.demandId,
                label: adUnit.label,
                pricefloor: adUnit.pricefloor,
                bidType: AdBidType(demandType: adUnit.demandType)
            )
        }
    }
    
    let id: String
    let adType: AdType
    let price: Price
    let currencyCode: Currency?
    let networkName: String
    let roundId: String
    let auctionId: String
    let adUnit: AdNetworkUnit
    
    init(
        id: String,
        adType: AdType,
        price: Price,
        currencyCode: Currency?,
        networkName: String,
        roundId: String,
        auctionId: String,
        adUnit: AdNetworkUnitModel
    ) {
        self.id = id
        self.adType = adType
        self.price = price
        self.currencyCode = currencyCode
        self.networkName = networkName
        self.roundId = roundId
        self.auctionId = auctionId
        self.adUnit = adUnit
    }
    
    convenience init<T: Bid>(bid: T) where T.DemandAdType: DemandAd {
        self.init(
            id: bid.ad.id,
            adType: bid.adType,
            price: bid.price,
            currencyCode: bid.ad.currency,
            networkName: bid.ad.networkName ?? bid.adUnit.demandId,
            roundId: bid.roundConfiguration.roundId,
            auctionId: bid.auctionConfiguration.auctionId,
            adUnit: AdNetworkUnitModel(bid.adUnit)
        )
    }
    
    convenience init(impression: Impression) {
        self.init(
            id: impression.ad.id,
            adType: impression.adType,
            price: impression.price,
            currencyCode: impression.ad.currency,
            networkName: impression.ad.networkName ?? impression.demandId,
            roundId: impression.roundConfiguration.roundId,
            auctionId: impression.auctionConfiguration.auctionId,
            adUnit: AdNetworkUnitModel(
                uid: impression.adUnitUid,
                demandId: impression.demandId,
                label: impression.adUnitLabel,
                pricefloor: impression.adUnitPricefloor,
                bidType: AdBidType(demandType: impression.demandType)
            )
        )
    }
}


fileprivate extension Formatter {
    static let price: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}


fileprivate extension AdBidType {
    init(demandType: DemandType) {
        switch demandType {
        case .bidding: self = .rtb
        default: self = .cpm
        }
    }
    
    var stringValue: String {
        switch self {
        case .cpm: return "CPM"
        case .rtb: return "RTB"
        }
    }
}


extension AdContainer {
    override var description: String {
        let components: [String?] = [
            "\(adType.stringValue) (\(adUnit.bidType.stringValue)) ad #\(adUnit.uid)",
            Formatter.price.string(from: price as NSNumber).map { "price \($0)" },
            "network '\(networkName)'",
        ]
        
        return components
            .compactMap { $0 }
            .joined(separator: ", ")
            .capitalized
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(adUnit.uid)
        hasher.combine(auctionId)
        hasher.combine(roundId)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? AdContainer else { return false }
        return object.id == id && 
        object.adUnit.uid == object.adUnit.uid &&
        object.auctionId == auctionId &&
        object.roundId == roundId
    }
}


