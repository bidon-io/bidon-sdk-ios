//
//  BannerFormat.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation
import UIKit


@objc(BDNBannerFormat)
public enum BannerFormat: Int, Codable, CustomStringConvertible {
    case banner
    case leaderboard
    case mrec
    case adaptive

    public var preferredSize: CGSize {
        switch self {
        case .banner:
            return CGSize(width: 320, height: 50)
        case .leaderboard:
            return CGSize(width: 728, height: 90)
        case .mrec:
            return CGSize(width: 300, height: 250)
        case .adaptive:
            return UIDevice.bd.isPhone ?
            CGSize(width: UIScreen.main.bounds.width, height: 50) :
            CGSize(width: UIScreen.main.bounds.width, height: 90)
        }
    }

    public var description: String {
        return stringValue.capitalized
    }

    var stringValue: String {
        switch self {
        case .banner: return "banner"
        case .leaderboard: return "leaderboard"
        case .mrec: return "mrec"
        case .adaptive: return "adaptive"
        }
    }

    init(_ stringValue: String) throws {
        switch stringValue {
        case "banner": self = .banner
        case "leaderboard": self = .leaderboard
        case "mrec": self = .mrec
        case "adaptive": self = .adaptive
        default: throw SdkError("Unable to create with '\(stringValue)'")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue.uppercased())
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        try self.init(stringValue)
    }
}
