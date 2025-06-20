//
//  AuctionResultReport.swift
//  Bidon
//
//  Created by Bidon Team on 03.03.2023.
//

import Foundation


enum AuctionResultStatus: Codable {
    case unknown
    case success
    case fail
    case cancelled

    private var stringValue: String {
        switch self {
        case .unknown:          return "UNKNOWN"
        case .success:          return "SUCCESS"
        case .fail:             return "FAIL"
        case .cancelled:        return "AUCTION_CANCELLED"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "UNKNOWN":             self = .unknown
        case "SUCCESS":             self = .success
        case "FAIL":                self = .fail
        case "AUCTION_CANCELLED":   self = .cancelled
        default:
            let ctx = DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to create AuctionResultStatus from '\(value)'"
            )
            throw DecodingError.dataCorrupted(ctx)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
