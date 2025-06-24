//
//  MediationError.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public enum MediationError: Error {
    case noBid(String?)
    case noFill(String?)
    case unknownAdapter
    case adapterNotInitialized
    case bidTimeoutReached
    case fillTimeoutReached
    case networkError
    case incorrectAdUnitId
    case noAppropriateAdUnitId
    case auctionCancelled
    case adFormatNotSupported
    case unspecifiedException(String)
    case belowPricefloor

    var rawValue: String {
        switch self {
        case .noBid:
            return "noBid"
        case .noFill:
            return "noFill"
        case .unknownAdapter:
            return "unknownAdapter"
        case .adapterNotInitialized:
            return "adapterNotInitialized"
        case .bidTimeoutReached:
            return "bidTimeoutReached"
        case .fillTimeoutReached:
            return "fillTimeoutReached"
        case .networkError:
            return "networkError"
        case .incorrectAdUnitId:
            return "incorrectAdUnitId"
        case .noAppropriateAdUnitId:
            return "noAppropriateAdUnitId"
        case .auctionCancelled:
            return "auctionCancelled"
        case .adFormatNotSupported:
            return "adFormatNotSupported"
        case .belowPricefloor:
            return "belowPricefloor"
        case .unspecifiedException:
            return "unspecifiedException"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "noBid":
            self = .noBid(nil)
        case "noFill":
            self = .noFill(nil)
        case "unknownAdapter":
            self = .unknownAdapter
        case "adapterNotInitialized":
            self = .adapterNotInitialized
        case "bidTimeoutReached":
            self = .bidTimeoutReached
        case "fillTimeoutReached":
            self = .fillTimeoutReached
        case "networkError":
            self = .networkError
        case "incorrectAdUnitId":
            self = .incorrectAdUnitId
        case "noAppropriateAdUnitId":
            self = .noAppropriateAdUnitId
        case "auctionCancelled":
            self = .auctionCancelled
        case "adFormatNotSupported":
            self = .adFormatNotSupported
        case "belowPricefloor":
            self = .belowPricefloor
        default:
            self = .unspecifiedException(rawValue)
        }
    }
}
