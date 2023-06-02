//
//  SDK.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


fileprivate struct SdkInjectionKey: InjectionKey {
    static var currentValue: Sdk = BidonSdk.shared
}


fileprivate struct AuctionContextInjectionKey: InjectionKey {
    static var currentValue: SdkContext = BidonSdk.shared
}


internal extension InjectedValues {
    var sdk: Sdk {
        get { Self[SdkInjectionKey.self] }
        set { Self[SdkInjectionKey.self] = newValue }
    }
}


public extension InjectedValues {
    var context: SdkContext {
        get { Self[AuctionContextInjectionKey.self] }
        set { Self[AuctionContextInjectionKey.self] = newValue }
    }
}


public protocol SdkContext {
    var isTestMode: Bool { get }
    var extras: [String: AnyHashable] { get }
}


internal protocol Sdk: SdkContext {
    var adaptersRepository: AdaptersRepository { get }
    var environmentRepository: EnvironmentRepository { get }
}


extension BidonSdk: Sdk {}
