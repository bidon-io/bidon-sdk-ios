//
//  BidMachineProgrammaticDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon


class BidMachineProgrammaticDemandProvider<AdObject: BidMachineAdProtocol>: BidMachineBaseDemandProvider<AdObject>, ProgrammaticDemandProvider {
    
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
}
