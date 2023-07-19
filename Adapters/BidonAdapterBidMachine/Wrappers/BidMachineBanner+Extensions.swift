//
//  BidMachineBanner+Extensions.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation
import Bidon
import BidMachine
import BidMachineApiCore


extension BidMachineBanner: AdViewContainer {
    public var isAdaptive: Bool { false }
}


extension BidMachineApiCore.PlacementFormat {
    init(format: BannerFormat) {
        switch format {
        case .banner: self = .banner320x50
        case .leaderboard: self = .banner728x90
        case .adaptive: self = .banner
        case .mrec: self = .banner300x250
        }
    }
}
