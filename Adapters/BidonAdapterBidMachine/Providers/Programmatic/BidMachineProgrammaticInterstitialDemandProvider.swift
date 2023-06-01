//
//  BidMachineInterstitialDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon


final class BidMachineProgrammaticInterstitialDemandProvider: BidMachineProgrammaticDemandProvider<BidMachineInterstitial> {
    override var placementFormat: BidMachineApiCore.PlacementFormat { .interstitial }
}


extension BidMachineProgrammaticInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: BidMachineAdDemand<BidMachineInterstitial>, from viewController: UIViewController) {
        guard ad.ad.canShow else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
            return
        }
        
        ad.ad.controller = viewController
        ad.ad.presentAd()
    }
}
