//
//  AdProtocol.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 04.07.2022.
//

import Foundation


@objc(BDNAdBidType)
public enum AdBidType: Int {
    case cpm = 1
    case rtb
}


@objc(BDNAdNetworkUnit)
public protocol AdNetworkUnit {
    var uid: String { get }
    var demandId: String { get }
    var label: String { get }
    var pricefloor: Price { get }
    var bidType: AdBidType { get }
    var extras: [String: BidonDecodable] { get }
    var extrasJsonString: String? { get }
}


@objc(BDNAd)
public protocol Ad {
    @objc var id: String { get }
    @objc var adType: AdType { get }
    @objc var price: Price { get }
    @objc var currencyCode: Currency? { get }
    @objc var networkName: String { get }
    @objc var dsp: String? { get }
    @objc var auctionId: String { get }
    @objc var adUnit: AdNetworkUnit { get }
}
