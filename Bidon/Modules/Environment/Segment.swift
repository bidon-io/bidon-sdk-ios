//
//  Segment.swift
//  Bidon
//
//  Created by Bidon Team on 14.06.2023.
//

import Foundation


@objc(BDNGender)
public enum Gender: Int {
    case male
    case female
    case other
}


@objc(BDNSegment)
public protocol Segment {
    var id: String? { get }
    
    var gender: Gender { get set }
    
    var age: Int { get set }
    
    var level: Int { get set }
    
    var isPaid: Bool { get set }
    
    var inAppAmount: Price { get set }
    
    var customAttributes: [String: AnyHashable] { get }
    
    func setCustomAttribute(_ customAttribute: AnyHashable, for key: String)
}


internal protocol SegmentResponse {
    var id: String { get }
}
