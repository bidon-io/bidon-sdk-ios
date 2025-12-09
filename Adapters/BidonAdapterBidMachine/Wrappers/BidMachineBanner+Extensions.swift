//
//  BidMachineBanner+Extensions.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation
import Bidon
import BidMachine


extension BidMachineBanner: AdViewContainer {
    public var isAdaptive: Bool { false }
}


extension BannerFormat {
    var bmBannerFormat: AdFormat {
        switch self {
        case .banner:
            return .banner320x50
        case .leaderboard:
            return .banner728x90
        case .mrec:
            return .banner300x250
        case .adaptive:
            return .bannerAdaptive(width: UInt32(self.preferredSize.width))
        }
    }
}
