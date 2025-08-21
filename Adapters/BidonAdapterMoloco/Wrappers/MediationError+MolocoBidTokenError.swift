//
//  MediationError+MolocoSDK.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import Bidon
import MolocoSDK


extension MediationError {
    init(from moloco: MolocoBidTokenError) {
        switch moloco {
        case .from(let original):
            if let urlErr = original as? URLError {
                self = .networkError
            } else {
                self = .unspecifiedException("Upstream error: \(String(describing: original))")
            }

        case .requestError(let response):
            switch response.statusCode {
            case 400...499:
                self = .noBid("HTTP \(response.statusCode)")
            case 500...599:
                self = .networkError
            default:
                self = .noBid("HTTP \(response.statusCode)")
            }

        case .deserializationFailed:
            self = .noBid("Deserialization failed")

        case .clientComponentFailure:
            self = .unspecifiedException("Client component failure")

        case .noResponse:
            self = .networkError

        case .notSupported:
            self = .adFormatNotSupported

        case .invalidServerTokenFormat:
            self = .noBid("Invalid server token format")

        case .invalidJwtToken:
            self = .noBid("Invalid JWT token")
        @unknown default:
            self = .unspecifiedException("Moloco has not provided bidding token")
        }
    }
}

extension MediationError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noBid(let reason):
            return "No bid" + (reason.map { ": \($0)" } ?? "")
        case .noFill(let reason):
            return "No fill" + (reason.map { ": \($0)" } ?? "")
        case .unknownAdapter:
            return "Unknown adapter"
        case .adapterNotInitialized:
            return "Adapter not initialized"
        case .bidTimeoutReached:
            return "Bid timeout reached"
        case .fillTimeoutReached:
            return "Fill timeout reached"
        case .networkError:
            return "Network error"
        case .incorrectAdUnitId:
            return "Incorrect Ad Unit ID"
        case .noAppropriateAdUnitId:
            return "No appropriate Ad Unit ID"
        case .auctionCancelled:
            return "Auction cancelled"
        case .adFormatNotSupported:
            return "Ad format not supported"
        case .unspecifiedException(let msg):
            return "Unspecified exception: \(msg)"
        case .belowPricefloor:
            return "Below price floor"
        }
    }
}
