//
//  DemandResult.swift
//  Bidon
//
//  Created by Bidon Team on 12.09.2022.
//

import Foundation


enum DemandMediationStatus: Codable {
    case unknown
    case win
    case lose
    case cache
    case error(MediationError)
    
    var isWin: Bool {
        switch self {
        case .win: return true
        default: return false
        }
    }

    var isUnknown: Bool {
        switch self {
        case .unknown: return true
        default: return false
        }
    }

    var isCancelled: Bool {
        switch self {
        case .error(let error):
            switch error {
            case .auctionCancelled:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    internal var stringValue: String {
        switch self {
        case .unknown:          return "UNKNOWN"
        case .win:              return "WIN"
        case .lose:             return "LOSE"
        case .cache:            return "CACHE"
        case .error(let error): return error.rawValue.camelCaseToSnakeCase().uppercased()
        }
    }

    init(_ error: MediationError) {
        self = .error(error)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "UNKNOWN": self = .unknown
        case "WIN": self = .win
        case "LOSE": self = .lose
        case "CACHE": self = .cache
        default:
            guard let error = MediationError(rawValue: value.snakeCaseToCamelCase()) else {
                let ctx = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to create DemandResultStatus from '\(value)'"
                )
                throw DecodingError.dataCorrupted(ctx)}
            self = .error(error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
