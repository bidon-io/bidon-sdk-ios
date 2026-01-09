//
//  ZmaticooSdkBridge.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Foundation
import Bidon

/// A small indirection layer to isolate all direct references to the zMaticoo iOS SDK.
/// This lets the adapter compile even while the SDK integration is not finalized.
enum ZmaticooSdkBridge {
    /// Name of the module to import once the iOS SDK is known.
    /// Replace in `#if canImport(...)` blocks when the actual module name is confirmed.
    private static let sdkNotLinkedMessage =
        "zMaticoo iOS SDK is not linked. Add the correct CocoaPods dependency in Podfile and run pod install."

    static var sdkVersion: String {
        // TODO: Return actual SDK version once the iOS SDK is integrated.
        return "unknown"
    }

    static var isInitialized: Bool {
        // TODO: Return actual init state if SDK provides it.
        return false
    }

    static func initialize(
        parameters: ZmaticooParameters,
        context: SdkContext,
        completion: @escaping (SdkError?) -> Void
    ) {
        // TODO: Implement SDK initialization once iOS docs are clarified.
        // For now keep adapter non-initialized to prevent accidental usage without the SDK.
        completion(.message(sdkNotLinkedMessage))
    }

    static func biddingToken(
        placementId: String,
        timestampMs: Int64
    ) -> Result<String, MediationError> {
        // Docs (Android) say: MaticooAds.getBiddingToken(placementId, timeStamp)
        // TODO: Implement for iOS when API is confirmed.
        _ = placementId
        _ = timestampMs
        return .failure(.unspecifiedException(sdkNotLinkedMessage))
    }
}


