//
//  AppodealAdvertisingServiceInitializator.swift
//  Sandbox
//
//  Created by Bidon Team on 14.02.2023.
//

import Foundation
import Appodeal
import Bidon



final class AppodealDefaultAdInitializationWrapper: NSObject, AppodealAdInitializationWrapper {
    private var appKey: String!
    private var adTypes: AppodealAdType!

    private var continuation: CheckedContinuation<Void, Never>!

    override init() {
        super.init()
        Appodeal.setInitializationDelegate(self)
    }

    func initialize(
        appKey: String,
        adTypes: AppodealAdType
    ) async {
        self.appKey = appKey
        self.adTypes = adTypes
        await withCheckedContinuation { [unowned self] continuation in
            self.continuation = continuation
            DispatchQueue.main.async { [unowned self] in
                self.initializeAppodealMediation()
            }
        }
    }

    private func initializeAppodealMediation() {
        // We need to cache advertisement manually
        // to properly control ad lifecycle
        Appodeal.setAutocache(false, types: adTypes)
        // Disable precache because we need the most
        // expensive ad
        Appodeal.setTriggerPrecacheCallbacks(false, types: adTypes)
        Appodeal.initialize(withApiKey: appKey, types: adTypes)
    }

    private func initializeBidon() {
        BidonSdk.setExtraValue(Appodeal.segmentId(), for: "appodeal_segment_id")
        BidonSdk.initialize(appKey: appKey) { [unowned self] in
            self.continuation.resume()
            self.continuation = nil
        }
    }
}


extension AppodealDefaultAdInitializationWrapper: AppodealInitializationDelegate {
    func appodealSDKDidInitialize() {
        initializeBidon()
    }
}
