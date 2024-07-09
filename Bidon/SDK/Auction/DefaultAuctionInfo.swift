//
//  DefaultAuctionInfo.swift
//  Bidon
//
//  Created by Евгения Григорович on 04/07/2024.
//

import Foundation

final class DefaultAuctionInfo: AuctionInfo {
    var auctionId: String?
    var auctionConfigurationId: String?
    var auctionConfigurationUid: String?
    var auctionPricefloor: NSNumber?
    var noBids: [BidInfo]?
    var adUnits: [AdUnitInfo]?
    
    var description: String? {
        let dictRepresentation: [String: Any] = [
            "auctionId": auctionId ?? "null",
            "auctionConfigurationId": auctionConfigurationId ?? "null",
            "auctionConfigurationUid": auctionConfigurationUid ?? "null",
            "auctionPricefloor": auctionPricefloor ?? "null",
            "noBids": noBids?.map({ $0.dictionaryRepresentation() }) ?? "null",
            "adUnits": adUnits?.map({ $0.dictionaryRepresentation() }) ?? "null",
        ]
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: dictRepresentation, options: .withoutEscapingSlashes) {
                let convertedString = String(data: data, encoding: .utf8)
                return convertedString
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: dictRepresentation, options: []) {
                let convertedString = String(data: data, encoding: .utf8)
                return convertedString
            }
        }
        
        return nil
    }
}

final class DefaultBidInfo: BidInfo {
    var demandId: String
    var label: String?
    var price: NSNumber?
    var uid: String?
    var bidType: String?
    var ext: [String: Any]?

    init(_ bid: AdUnitModel) {
        self.demandId = bid.demandId
        self.label = bid.label
        self.price = NSNumber(bid.pricefloor)
        self.uid = bid.uid
        self.bidType = bid.bidType.rawValue
        self.ext = bid.extrasDictionary
    }
}

final class DefaultAdUnitInfo: AdUnitInfo {
    var demandId: String
    var label: String?
    var price: NSNumber?
    var uid: String?
    var bidType: String?
    var fillStartTs: NSNumber?
    var fillFinishTs: NSNumber?
    var tokenStartTs: NSNumber?
    var tokenFinishTs: NSNumber?
    var status: String?
    var ext: [String: Any]?
    
    init(_ bid: any AuctionDemandReport) {
        self.demandId = bid.demandId
        self.label = bid.adUnit?.label
        self.price = NSNumber(bid.adUnit?.pricefloor)
        self.uid = bid.adUnit?.uid
        self.bidType = bid.adUnit?.bidType.rawValue
        self.fillStartTs = NSNumber(bid.startTimestamp)
        self.fillFinishTs = NSNumber(bid.finishTimestamp)
        self.tokenStartTs = NSNumber(bid.tokenStartTimestamp)
        self.tokenFinishTs = NSNumber(bid.tokenFinishTimestamp)
        self.status = bid.status.stringValue
        self.ext = bid.adUnit?.extrasDictionary
    }
}

private extension NSNumber {
    convenience init?(_ value: Double?) {
        guard let value = value else { return nil }
        self.init(value: value)
    }
    
    convenience init?(_ value: UInt?) {
        guard let value = value else { return nil }
        self.init(value: value)
    }
}

private extension BidInfo {
    
    func dictionaryRepresentation() -> [String: Any] {
        return [
            "demandId": demandId,
            "label": label ?? "null",
            "price": price ?? "null",
            "uid": uid ?? "null",
            "bidType": bidType ?? "null",
            "ext": ext ?? "null"
        ]
    }
}

private extension AdUnitInfo {
    
    func dictionaryRepresentation() -> [String: Any] {
        return [
            "demandId": demandId,
            "label": label ?? "null",
            "price": price ?? "null",
            "uid": uid ?? "null",
            "bidType": bidType ?? "null",
            "ext": ext ?? "null",
            "fillStartTs": fillStartTs ?? "null",
            "fillFinishTs": fillFinishTs ?? "null",
            "tokenStartTs": tokenStartTs ?? "null",
            "tokenFinishTs": tokenFinishTs ?? "null",
            "status": status ?? "null"
        ]
    }
}
