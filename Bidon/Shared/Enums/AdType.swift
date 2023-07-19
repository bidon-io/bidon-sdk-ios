//
//  AdType.swift
//  Bidon
//
//  Created by Bidon Team on 12.04.2023.
//

import Foundation


@objc
public enum AdType: Int, Codable {
    case banner = 0
    case interstitial = 1
    case rewarded = 2
    
    var stringValue: String {
        switch self {
        case .banner: return "banner"
        case .interstitial: return "interstitial"
        case .rewarded: return "rewarded"
        }
    }
    
    enum Key: CodingKey {
        case rawValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(stringValue, forKey: .rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let raw = try container.decode(String.self, forKey: .rawValue)
        switch raw {
        case "banner": self = .banner
        case "interstitial": self = .interstitial
        case "rewarded": self = .rewarded
        default:
            let ctx = DecodingError.Context(
                codingPath: [Key.rawValue],
                debugDescription: "Unsupported value '\(raw)'"
            )
            throw DecodingError.valueNotFound(AdType.self, ctx)
        }
    }
}


extension AdType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .banner: return "Banner"
        case .interstitial: return "Interstitial"
        case .rewarded: return "Rewarded Ad"
        }
    }
}

