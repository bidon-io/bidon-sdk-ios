//
//  AuctionInfo.swift
//  Bidon
//
//  Created by Евгения Григорович on 04/07/2024.
//

import Foundation

@objc(BDNAuctionInfo)
public protocol AuctionInfo {
    var auctionId: String? { get set }
    var auctionConfigurationId: String? { get set }
    var auctionConfigurationUid: String? { get set }
    var auctionPricefloor: NSNumber? { get set }
    var noBids: [BidInfo]? { get set }
    var adUnits: [AdUnitInfo]? { get set }
    
    var description: String? { get }
}

@objc(BDNBidInfo)
public protocol BidInfo {
    var demandId: String { get }
    var label: String? { get }
    var price: NSNumber? { get }
    var uid: String? { get }
    var bidType: String? { get }
    var ext: [String: Any]? { get }
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
    var tokenStartTs: NSNumber? { get }
    var tokenFinishTs: NSNumber? { get }
    var status: String? { get }
    var ext: [String: Any]? { get }
}
