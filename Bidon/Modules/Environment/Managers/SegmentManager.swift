//
//  SegmentManager.swift
//  Bidon
//
//  Created by Stas Kochkin on 14.06.2023.
//

import Foundation


final class SegmentManager: Segment, Environment {
    @UserDefaultOptional(Constants.UserDefaultsKey.segmentId)
    var id: String?
    
    var gender: Gender = .other
    
    var age: Int = .unknown
    
    var level: Int = .unknown
    
    var isPaid: Bool = false
    
    var inAppAmount: Double = .unknown
    
    private(set) var customAttributes: [String : AnyHashable] = [:]
    
    func setCustomAttribute(
        _ customAttribute: AnyHashable,
        for key: String
    ) {
        customAttributes[key] = customAttribute
    }
}


private extension Int {
    static var unknown: Int { -1 }
}
