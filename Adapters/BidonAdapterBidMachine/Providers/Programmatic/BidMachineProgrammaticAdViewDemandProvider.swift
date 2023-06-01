//
//  BidMachineAdViewDemandSourceAdapter.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachineApiCore
import BidMachine
import Bidon


final class BidMachineProgrammaticAdViewDemandProvider: BidMachineProgrammaticDemandProvider<BidMachineBanner> {
    private let format: BannerFormat
    
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    override var placementFormat: BidMachineApiCore.PlacementFormat { .init(format: format) }
    
    init(context: AdViewContext) {
        self.format = context.format
        
        super.init()
    }
}


extension BidMachineProgrammaticAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }
    
    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}

