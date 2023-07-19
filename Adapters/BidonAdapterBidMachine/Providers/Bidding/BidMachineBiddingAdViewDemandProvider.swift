//
//  BidMachineBiddingAdViewDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation
import UIKit
import BidMachineApiCore
import BidMachine
import Bidon


final class BidMachineBiddingAdViewDemandProvider: BidMachineBiddingDemandProvider<BidMachineBanner> {
    private let format: BannerFormat
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    override var placementFormat: BidMachineApiCore.PlacementFormat { .init(format: format) }
    
    init(context: AdViewContext) {
        self.format = context.format
        
        super.init()
    }
}


extension BidMachineBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }
    
    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
