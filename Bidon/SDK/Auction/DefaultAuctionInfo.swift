//
//  DefaultAuctionInfo.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 04/07/2024.
//

import Foundation

final class DefaultAuctionInfo: AuctionInfo {
    var auctionId: String = ""
    var auctionConfigurationId: NSNumber?
    var auctionConfigurationUid: String?
    var auctionPricefloor: NSNumber = 0
    var noBids: [AdUnitInfo]?
    var adUnits: [AdUnitInfo]?
    var timeout: NSNumber = NSNumber(value: Constants.Timeout.defaultAuctionTimeout)

    var description: String? {
        let dictRepresentation: [String: Any] = [
            "auctionId": auctionId,
            "auctionConfigurationId": auctionConfigurationId ?? "null",
            "auctionConfigurationUid": auctionConfigurationUid ?? "null",
            "auctionPricefloor": auctionPricefloor,
            "noBids": noBids?.map({ $0.dictionaryRepresentation() }) ?? "null",
            "adUnits": adUnits?.map({ $0.dictionaryRepresentation() }) ?? "null"
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

final class DefaultAdUnitInfo: AdUnitInfo {
    var demandId: String
    var label: String?
    var price: NSNumber?
    var uid: String?
    var bidType: String?
    var fillStartTs: NSNumber?
    var fillFinishTs: NSNumber?
    var status: String
    var ext: [String: Any]?
    var extrasJsonString: String?

    init(_ bid: any AuctionDemandReport) {
        self.demandId = bid.demandId
        self.label = bid.adUnit?.label
        self.price = NSNumber(bid.adUnit?.pricefloor)
        self.uid = bid.adUnit?.uid
        self.bidType = bid.adUnit?.bidType.rawValue
        self.fillStartTs = NSNumber(bid.startTimestamp)
        self.fillFinishTs = NSNumber(bid.finishTimestamp)
        self.status = bid.status.stringValue
        self.ext = bid.adUnit?.extrasDictionary
        self.extrasJsonString = bid.adUnit?.extrasDictionary?.jsonString
    }

    init(_ bid: AdUnitModel) {
        self.demandId = bid.demandId
        self.label = bid.label
        self.price = NSNumber(bid.pricefloor)
        self.uid = bid.uid
        self.bidType = bid.bidType.rawValue
        self.status = DemandMediationStatus(.noBid(nil)).stringValue
        self.ext = bid.extrasDictionary

        if let extrasDictionary = bid.extrasDictionary,
           JSONSerialization.isValidJSONObject(extrasDictionary),
            let extrasData = try? JSONSerialization.data(withJSONObject: extrasDictionary, options: []) {
            self.extrasJsonString = String(data: extrasData, encoding: .utf8)
        }
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

private extension AdUnitInfo {
    func dictionaryRepresentation() -> [String: Any] {
        return [
            "demandId": demandId,
            "label": label ?? "null",
            "price": price ?? "null",
            "uid": uid ?? "null",
            "bidType": bidType ?? "null",
            "fillStartTs": fillStartTs ?? "null",
            "fillFinishTs": fillFinishTs ?? "null",
            "status": status.description,
            "ext": ext?.mapToStringedValues() ?? "null"
        ]
    }
}

private extension Dictionary where Key == String {
    func mapToStringedValues() -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in self {
            result[key] = BidonDecodable(value: value).stringValue
        }
        return result
    }
}
