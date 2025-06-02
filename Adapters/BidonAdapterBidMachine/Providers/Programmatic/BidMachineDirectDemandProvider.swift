//
//  BidMachineProgrammaticDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon


class BidMachineDirectDemandProvider<AdObject: BidMachineAdProtocol>: BidMachineBaseDemandProvider<AdObject>, DirectDemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let configuration = try BidMachineSdk.shared.requestConfiguration(placementFormat)
            var parameters = adUnitExtras.customParameters ?? [String: String]()
            parameters["mediation_mode"] = "bidon"
            
            configuration.populate { builder in
                builder.appendPriceFloor(pricefloor, UUID().uuidString)
                builder.withCustomParameters(parameters)
            }
            
            BidMachineSdk.shared.ad(AdObject.self, configuration) { [weak self] ad, error in
                guard let self = self else { return }
                
                guard let ad = ad, error == nil else {
                    response(.failure(.noFill(error?.localizedDescription)))
                    return
                }
                
                ad.controller = UIApplication.shared.bd.topViewcontroller
                ad.delegate = self
                
                self.response = response
                self.ad = ad
                
                ad.loadAd()
            }
        } catch let error {
            response(.failure(.unspecifiedException(error.localizedDescription)))
        }
    }
}
