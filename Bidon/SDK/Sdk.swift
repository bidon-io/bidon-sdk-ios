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


fileprivate struct AdTypeInjectionKey: InjectionKey {
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
        get { Self[AdTypeInjectionKey.self] }
        set { Self[AdTypeInjectionKey.self] = newValue }
    }
}


public protocol SdkContext {
    var isTestMode: Bool { get }
    var extras: [String: AnyHashable] { get }
    var regulations: Regulations { get }
    var segment: Segment { get }
}


internal protocol Sdk: SdkContext {
    var adaptersRepository: AdaptersRepository { get }
    var environmentRepository: EnvironmentRepository { get }
    
    func updateSegmentIfNeeded(_ segment: SegmentResponse?)
}


extension BidonSdk: Sdk {
    @objc
    public var extras: [String: AnyHashable] {
        environmentRepository.environment(ExtrasManager.self).extras
    }
    
    public var segment: Segment {
        environmentRepository.environment(SegmentManager.self)
    }
    
    public var regulations: Regulations {
        environmentRepository.environment(RegulationsManager.self)
    }
}
