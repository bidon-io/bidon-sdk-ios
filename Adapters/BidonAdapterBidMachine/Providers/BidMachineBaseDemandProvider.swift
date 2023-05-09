//
//  BidMachineBaseDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 23.02.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon


class BidMachineBaseDemandProvider<AdObject: BidMachineAdProtocol>: NSObject, BidMachineAdDelegate {
    typealias AdType = BidMachineAdDemand<AdObject>
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    var placementFormat: BidMachineApiCore.PlacementFormat {
        fatalError("Base demand provider doesn't provide placement format")
    }
    
    private var response: DemandProviderResponse?
    
    func didLoadAd(_ ad: BidMachineAdProtocol) {
        defer { response = nil }
        
        if let ad = ad as? AdObject {
            let wrapper = BidMachineAdDemand(ad)
            response?(.success(wrapper))
            
        } else {
            response?(.failure(.unscpecifiedException))
        }
    }
    
    func didFailLoadAd(_ ad: BidMachineAdProtocol, _ error: Error) {
        response?(.failure(.noFill))
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
}


extension BidMachineBaseDemandProvider: ProgrammaticDemandProvider {
    func bid(_ pricefloor: Price, response: @escaping DemandProviderResponse) {
        do {
            let configuration = try BidMachineSdk.shared.requestConfiguration(placementFormat)
            
            configuration.populate { builder in
                builder.appendPriceFloor(pricefloor, UUID().uuidString)
                builder.withCustomParameters(["mediation_mode": "bidon"])
            }
            
            BidMachineSdk.shared.ad(AdObject.self, configuration) { ad, error in
                guard let ad = ad, error == nil else {
                    response(.failure(.noBid))
                    return
                }
                
                let wrapper = AdType(ad)
                response(.success(wrapper))
            }
        } catch {
            response(.failure(.unscpecifiedException))
        }
    }
    
    func fill(ad: AdType, response: @escaping DemandProviderResponse) {
        self.response = response
        
        ad.ad.controller = UIApplication.shared.bd.topViewcontroller
        ad.ad.delegate = self
        ad.ad.loadAd()
    }
    
    func notify(ad: AdType, event: AuctionEvent) {
        switch event {
        case .win:
            BidMachineSdk.shared.notifyMediationWin(ad.ad)
        case .lose(let winner, let eCPM):
            BidMachineSdk.shared.notifyMediationLoss(
                winner.networkName,
                eCPM,
                ad.ad
            )
        }
    }
}
