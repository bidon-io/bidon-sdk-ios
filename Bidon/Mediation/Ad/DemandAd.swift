//
//  DemandAd.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation

@objc
public protocol DemandAd {
    @objc var id: String { get }

    @objc optional
    var networkName: String { get }

    @objc optional
    var dsp: String { get }

    @objc optional
    var price: Price { get }

    @objc optional
    var currency: Currency { get }
}
