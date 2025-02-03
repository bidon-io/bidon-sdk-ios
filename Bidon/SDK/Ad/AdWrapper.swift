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
        let extras: [String: BidonDecodable]
        var extrasJsonString: String?
        
        init(
            uid: String,
            demandId: String,
            label: String,
            pricefloor: Price,
            bidType: AdBidType,
            extras: [String: BidonDecodable]
        ) {
            self.uid = uid
            self.demandId = demandId
            self.pricefloor = pricefloor
            self.label = label
            self.bidType = bidType
            self.extras = extras
            self.extrasJsonString = extras.jsonString
            super.init()
        }
        
        convenience init(_ adUnit: AnyAdUnit) {
            self.init(
                uid: adUnit.uid,
                demandId: adUnit.demandId,
                label: adUnit.label,
                pricefloor: adUnit.pricefloor,
                bidType: AdBidType(bidType: adUnit.bidType),
                extras: adUnit.extrasDictionary ?? [:]
            )
        }
    }
    
    let id: String
    let adType: AdType
    let price: Price
    let currencyCode: Currency?
    let networkName: String
    let dsp: String?
    let auctionId: String
    let adUnit: AdNetworkUnit
    
    init(
        id: String,
        adType: AdType,
        price: Price,
        currencyCode: Currency?,
        networkName: String,
        dsp: String?,
        auctionId: String,
        adUnit: AdNetworkUnitModel
    ) {
        self.id = id
        self.adType = adType
        self.price = price
        self.currencyCode = currencyCode
        self.networkName = networkName
        self.dsp = dsp
        self.auctionId = auctionId
        self.adUnit = adUnit
    }
    
    convenience init<T: Bid>(bid: T) where T.DemandAdType: DemandAd {
        self.init(
            id: bid.ad.id,
            adType: bid.adType,
            price: bid.price,
            currencyCode: bid.ad.currency,
            networkName: bid.adUnit.demandId,
            dsp: bid.ad.dsp,
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
            networkName: impression.demandId,
            dsp: impression.ad.dsp,
            auctionId: impression.auctionConfiguration.auctionId,
            adUnit: AdNetworkUnitModel(
                uid: impression.adUnitUid,
                demandId: impression.demandId,
                label: impression.adUnitLabel,
                pricefloor: impression.adUnitPricefloor,
                bidType: AdBidType(bidType: impression.bidType), 
                extras: impression.adUnitExtras ?? [:]
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
    init(bidType: BidType) {
        switch bidType {
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
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? AdContainer else { return false }
        return object.id == id && 
        object.adUnit.uid == object.adUnit.uid &&
        object.auctionId == auctionId
    }
}


