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
            eCPM: bid.ad.eCPM ?? bid.lineItem?.pricefloor ?? bid.eCPM,
            networkName: bid.ad.networkName,
            dsp: bid.ad.dsp,
            adUnitId: bid.lineItem?.adUnitId,
            roundId: bid.roundId,
            auctionId: bid.metadata.id,
            currencyCode: bid.ad.currency ?? .default
        )
    }
    
    convenience init(impression: Impression) {
        self.init(
            id: impression.ad.id,
            adType: impression.adType,
            eCPM: impression.ad.eCPM ?? impression.lineItem?.pricefloor ?? impression.eCPM,
            networkName: impression.ad.networkName,
            dsp: impression.ad.dsp,
            adUnitId: impression.lineItem?.adUnitId,
            roundId: impression.roundId,
            auctionId: impression.metadata.id,
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


extension AdContainer {
    override var description: String {
        let components: [String?] = [
            "\(adType.stringValue) ad #\(id)",
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


