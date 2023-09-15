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


@objc(BDNAd)
public protocol Ad {
    @objc var id: String { get }
    @objc var eCPM: Price { get }
    @objc var networkName: String { get }
    @objc var bidType: AdBidType { get }
    @objc var dsp: String? { get }
    @objc var adUnitId: String? { get }
    @objc var roundId: String? { get }
    @objc var auctionId: String? { get }
    @objc var currencyCode: Currency? { get }
    @objc var adType: AdType { get }
}

