//
//  AdWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


final class AdContainer: NSObject, Ad {
    let id: String
    let adType: AdType
    let eCPM: Price
    let networkName: String
    let bidType: AdBidType
    let dsp: String?
    let adUnitId: String?
    let roundId: String?
    var auctionId: String?
    let currencyCode: String?
    
    init(
        id: String,
        adType: AdType,
        eCPM: Price,
        networkName: String,
        bidType: AdBidType,
        dsp: String?,
        adUnitId: String?,
        roundId: String?,
        auctionId: String?,
        currencyCode: String?
    ) {
        self.id = id
        self.adType = adType
        self.eCPM = eCPM
        self.networkName = networkName
        self.bidType = bidType
        self.dsp = dsp
        self.adUnitId = adUnitId
        self.roundId = roundId
        self.auctionId = auctionId
        self.currencyCode = currencyCode
        
        super.init()
    }
    
    convenience init<T: Bid>(bid: T) {
        self.init(
            id: bid.ad.id,
            adType: bid.adType,
            eCPM: bid.eCPM,
            networkName: bid.ad.networkName,
            bidType: AdBidType(demandType: bid.demandType),
            dsp: bid.ad.dsp,
            adUnitId: bid.demandType.lineItem?.adUnitId,
            roundId: bid.roundConfiguration.roundId,
            auctionId: bid.auctionConfiguration.auctionId,
            currencyCode: bid.ad.currency ?? .default
        )
    }
    
    convenience init(impression: Impression) {
        self.init(
            id: impression.ad.id,
            adType: impression.adType,
            eCPM: impression.eCPM,
            networkName: impression.ad.networkName,
            bidType: AdBidType(demandType: impression.demandType),
            dsp: impression.ad.dsp,
            adUnitId: impression.demandType.lineItem?.adUnitId,
            roundId: impression.roundConfiguration.roundId,
            auctionId: impression.auctionConfiguration.auctionId,
            currencyCode: impression.ad.currency ?? .default
        )
    }
}


fileprivate extension Formatter {
    static let eCPM: NumberFormatter = {
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
            "\(adType.stringValue) (\(bidType.stringValue)) ad #\(id)",
            Formatter.eCPM.string(from: eCPM as NSNumber).map { "eCPM \($0)" },
            "network '\(networkName)'",
            dsp.map { "DSP '\($0)'" },
            adUnitId.map { "ad unit id \($0)" }
        ]
        
        return components
            .compactMap { $0 }
            .joined(separator: ", ")
            .capitalized
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(auctionId)
        hasher.combine(roundId)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? AdContainer else { return false }
        return object.id == id && object.auctionId == auctionId && object.adUnitId == adUnitId
    }
}


