//
//  BidMachineAdViewDemandSourceAdapter.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


final class BidMachineDirectAdViewDemandProvider: BidMachineDirectDemandProvider<BidMachineBanner> {
    private let format: BannerFormat

    weak var adViewDelegate: DemandProviderAdViewDelegate?

    override var placementFormat: PlacementFormat { .init(format: format) }

    init(context: AdViewContext) {
        self.format = context.format

        super.init()
    }
}


extension BidMachineDirectAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: BidMachineAdDemand<BidMachineBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: BidMachineAdDemand<BidMachineBanner>) {}
}
