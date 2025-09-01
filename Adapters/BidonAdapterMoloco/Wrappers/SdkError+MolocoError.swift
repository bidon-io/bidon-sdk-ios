//
//  SdkError+MolocoError.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import Bidon
import MolocoSDK


extension SdkError {
    static func from(_ e: MolocoError, underlying: Error? = nil) -> SdkError {
        switch e {
        case .unknown:
            return .generic(error: underlying ?? e)

        case .sdkInit, .sdkInvalidConfiguration:
            return .internalInconsistency

        case .adLoadFailed:
            return .noFill

        case .adLoadFailedSDKNotInit:
            return .internalInconsistency

        case .adLoadTimeoutError:
            return .message("Ad load timed out")

        case .adShowFailed:
            return .invalidPresentationState

        case .adShowFailedNotLoaded:
            return .invalidPresentationState

        case .adShowFailedAlreadyDisplaying:
            return .invalidPresentationState

        case .adBidParseFailed:
            return .message("Bid parse failed")

        case .adSignalCollectionFailed:
            return .message("Signal collection failed")
        @unknown default:
            return .unknown
        }
    }
}


extension SdkError {
    public init(_ error: Error?) {
        switch error {
        case let sdk as SdkError:
            self = sdk

        case let moloco as MolocoError:
            self = SdkError.from(moloco, underlying: moloco)

        case let some?:
            let ns = some as NSError
            if ns.domain == MolocoError._nsErrorDomain,
               let moloco = MolocoError(rawValue: ns.code) {
                self = SdkError.from(moloco, underlying: some)
            } else {
                self = .generic(error: some)
            }

        default:
            self = .unknown
        }
    }
}
