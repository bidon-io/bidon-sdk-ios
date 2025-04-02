//
//  LineItem.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


enum BidType: String, Codable {
    case bidding = "RTB"
    case direct = "CPM"
}


protocol AdUnit: Hashable {
    associatedtype ExtrasType
                           
    var demandId: String { get }
    var pricefloor: Price { get }
    var label: String { get }
    var uid: String { get }
    var bidType: BidType { get }
    var extras: ExtrasType { get }
    var extrasDictionary: [String: BidonDecodable]? { get }
    var timeout: TimeInterval { get }
}

@objc
public final class BidonDecodable: NSObject, Codable {
    @objc public let value: Any
    
    @objc public var stringValue: String? {
        return String(describing: value)
    }
    
    required public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), !container.decodeNil() {
            if let boolValue = try? container.decode(Bool.self) {
                value = boolValue
            } else if let intValue = try? container.decode(Int.self) {
                value = intValue
            } else if let doubleValue = try? container.decode(Double.self) {
                value = doubleValue
            } else if let stringValue = try? container.decode(String.self) {
                value = stringValue
            } else if let nestedDictionary = try? container.decode([String: BidonDecodable].self) {
                value = nestedDictionary.mapValues { $0.value }
            } else if let nestedArray = try? container.decode([BidonDecodable].self) {
                value = nestedArray.map { $0.value }
            } else {
                throw DecodingError.typeMismatch(BidonDecodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported value"))
            }
        } else {
            throw DecodingError.typeMismatch(BidonDecodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Nil value"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let nestedDictionary = value as? [String: Any] {
            let encodedDictionary = nestedDictionary.mapValues { BidonDecodable(value: $0) }
            try container.encode(encodedDictionary)
        } else if let nestedArray = value as? [Any] {
            let encodedArray = nestedArray.map { BidonDecodable(value: $0) }
            try container.encode(encodedArray)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported value"))
        }
    }

    @objc public init(value: Any) {
        self.value = value
    }
}

extension Dictionary where Key == String, Value: BidonDecodable {
    var jsonString: String? {
        let mappedDictionary = self.compactMapValues({ $0.value })
        if JSONSerialization.isValidJSONObject(mappedDictionary), let data = try? JSONSerialization.data(withJSONObject: mappedDictionary) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

typealias AnyAdUnit = any AdUnit
