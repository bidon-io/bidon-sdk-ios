//
//  SegmentManager.swift
//  Bidon
//
//  Created by Bidon Team on 14.06.2023.
//

import Foundation


final class SegmentManager: Segment, Environment {
    @UserDefaultOptional(Constants.UserDefaultsKey.segmentId)
    var id: String?
    
    var gender: Gender {
        get { _gender ?? .other }
        set { $_gender.wrappedValue = newValue }
    }
    
    var age: Int {
        get { _age ?? .unknown }
        set { $_age.wrappedValue = newValue }
    }
    
    var level: Int {
        get { _level ?? .unknown }
        set { $_level.wrappedValue = newValue }
    }
    
    var isPaid: Bool {
        get { _isPaid ?? false }
        set { $_isPaid.wrappedValue = newValue }
    }
    
    var inAppAmount: Double {
        get { _inAppAmount ?? .zero }
        set { $_inAppAmount.wrappedValue = newValue }
    }

    var customAttributes: [String : AnyHashable] {
        get { _customAttributes ?? [:] }
    }
    
    @Atomic
    var _gender: Gender?
    
    @Atomic
    var _age: Int?

    @Atomic
    var _level: Int?
    
    @Atomic
    var _isPaid: Bool?
    
    @Atomic
    var _inAppAmount: Double?
    
    @Atomic
    var _customAttributes: [String : AnyHashable]?
    
    func setCustomAttribute(
        _ customAttribute: AnyHashable,
        for key: String
    ) {
        var attributes = _customAttributes ?? [:]
        attributes[key] = customAttribute
        $_customAttributes.wrappedValue = attributes
    }
}


private extension Int {
    static var unknown: Int { -1 }
}
