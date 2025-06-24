//
//  SdkError.swift
//  Bidon
//
//  Created by Bidon Team on 12.04.2023.
//

import Foundation


public enum SdkError: Error, CustomStringConvertible {
    case generic(error: Error)
    case message(String)
    case unknown

    case noFill
    case cancelled
    case internalInconsistency
    case invalidPresentationState
    case unableToFindRootViewController

    public var description: String {
        switch self {
        case .noFill:
            return "No fill"
        case .internalInconsistency:
            return "Inconsistent state"
        case .unknown:
            return "Unknown"
        case .cancelled:
            return "Request has been cancelled"
        case .invalidPresentationState:
            return "Invalid presentation state"
        case .unableToFindRootViewController:
            return "Unable to find root view controller"
        case .generic(let error):
            return error.localizedDescription
        case .message(let message):
            return message
        }
    }

    public init(_ message: String) {
        self = .message(message)
    }

    public init(_ error: Error?) {
        if let error = error as? SdkError {
            self = error
        } else if let error = error {
            self = .generic(error: error)
        } else {
            self = .unknown
        }
    }
}


extension SdkError {
    var nserror: NSError {
        switch self {
        case .generic(let error):
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.unspecified.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: error.localizedDescription
                ]
            )
        case .message(let message):
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.unspecified.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: message
                ]
            )
        case .unknown:
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.unspecified.rawValue
            )
        case .noFill:
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.noFill.rawValue
            )
        case .cancelled:
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.auctionCancelled.rawValue
            )
        case .invalidPresentationState:
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.adNotReady.rawValue
            )
        case .internalInconsistency, .unableToFindRootViewController:
            return NSError(
                domain: ErrorCode.domain,
                code: ErrorCode.noContextFound.rawValue
            )
        }
    }
}
