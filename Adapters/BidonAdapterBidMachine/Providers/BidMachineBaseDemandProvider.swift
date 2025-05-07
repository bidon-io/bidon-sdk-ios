//
//  BidMachineBaseDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 23.02.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


class BidMachineBaseDemandProvider<AdObject: BidMachineAdProtocol>: NSObject, DemandProvider, BidMachineAdDelegate {
    typealias AdType = BidMachineAdDemand<AdObject>
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    var placementFormat: PlacementFormat {
        fatalError("Base demand provider doesn't provide placement format")
    }
    
    internal var response: DemandProviderResponse?
    internal var ad: AdObject?

    func didLoadAd(_ ad: BidMachineAdProtocol) {
        defer { response = nil }
        
        if let ad = ad as? AdObject {
            let wrapper = BidMachineAdDemand(ad)
            response?(.success(wrapper))
            
        } else {
            response?(.failure(.unspecifiedException("Mapping Error")))
        }
    }
    
    func didFailLoadAd(_ ad: BidMachineAdProtocol, _ error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
    }
    
    func didPresentAd(_ ad: BidMachineAdProtocol) {
        delegate?.providerWillPresent(self)
    }
    
    func didTrackImpression(_ ad: BidMachineAdProtocol) {
        guard let ad = ad as? AdObject else { return }

        let wrapper = BidMachineAdDemand(ad)
        revenueDelegate?.provider(self, didPayRevenue: ad.revenue, ad: wrapper)
    }
    
    func didFailPresentAd(_ ad: BidMachineAdProtocol, _ error: Error) {
        guard let ad = ad as? AdObject else { return }
        
        let wrapper = BidMachineAdDemand(ad)
        delegate?.provider(
            self,
            didFailToDisplayAd: wrapper,
            error: .generic(error: error)
        )
    }
    
    func didExpired(_ ad: BidMachineAdProtocol) {
        guard let ad = ad as? AdObject else { return }

        let wrapper = BidMachineAdDemand(ad)
        delegate?.provider(self, didExpireAd: wrapper)
    }
    
    func didDismissAd(_ ad: BidMachineAdProtocol) {
        delegate?.providerDidHide(self)
    }
    
    func didUserInteraction(_ ad: BidMachineAdProtocol) {
        delegate?.providerDidClick(self)
    }
    
    // Noop
    func willPresentScreen(_ ad: BidMachineAdProtocol) {}
    func didDismissScreen(_ ad: BidMachineAdProtocol) {}
    func didTrackInteraction(_ ad: BidMachineAdProtocol) {}
    
    func notify(ad: AdType, event: DemandProviderEvent) {
        switch event {
        case .win:
            BidMachineSdk.shared.notifyMediationWin(ad.ad)
        case .lose(let demandId, let winner, let price):
            BidMachineSdk.shared.notifyMediationLoss(
                winner.networkName ?? demandId,
                price,
                ad.ad
            )
        }
    }
}


