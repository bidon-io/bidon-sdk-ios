//
//  AuctionInfo.swift
//  Bidon
//
//  Created by Евгения Григорович on 04/07/2024.
//

import Foundation

@objc(BDNAdUnitStatus)
public enum AdUnitStatus: Int, CustomStringConvertible {
    case undefined
    case adLoadNotAttempted
    case adLoaded
    case failedToLoad
    
    public var description: String {
        switch self {
        case .undefined:
            return "UNDEFINED"
        case .adLoadNotAttempted:
            return "AD_LOAD_NOT_ATTEMPTED"
        case .adLoaded:
            return "AD_LOADED"
        case .failedToLoad:
            return "FAILED_TO_LOAD"
        }
    }
}

@objc(BDNAuctionInfo)
public protocol AuctionInfo {
    var auctionId: String? { get set }
    var auctionConfigurationId: String? { get set }
    var auctionConfigurationUid: String? { get set }
    var auctionPricefloor: NSNumber? { get set }
    var noBids: [AdUnitInfo]? { get set }
    var adUnits: [AdUnitInfo]? { get set }
    var timeout: NSNumber? { get set }
    
    var description: String? { get }
}

@objc(BDNAdUnitInfo)
public protocol AdUnitInfo {
    var demandId: String { get }
    var label: String? { get }
    var price: NSNumber? { get }
    var uid: String? { get }
    var bidType: String? { get }
    var fillStartTs: NSNumber? { get }
    var fillFinishTs: NSNumber? { get }
    var status: AdUnitStatus { get }
    var ext: [String: Any]? { get }
}
