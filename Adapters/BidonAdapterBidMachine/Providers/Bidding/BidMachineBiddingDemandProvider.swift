//
//  BidMachineBiddingDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon



class BidMachineBiddingDemandProvider<AdObject>: BidMachineBaseDemandProvider<AdObject>, ParameterizedBiddingDemandProvider
where AdObject: BidMachineAdProtocol {
    struct BiddingContext: Codable {
        var token: String
    }
    
    func fetchBiddingContext(
        response: @escaping (Result<BiddingContext, Bidon.MediationError>) -> ()
    ) {
        guard let token = BidMachineSdk.shared.token else {
            response(.failure(.unscpecifiedException))
            return
        }
        
        let context = BiddingContext(token: token) 
        response(.success(context))
    }
    
    func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let configuration = try BidMachineSdk.shared.requestConfiguration(placementFormat)
            
            configuration.populate { builder in
                builder.withPayload(payload)
                builder.withCustomParameters(["mediation_mode": "bidon"])
            }
            
            BidMachineSdk.shared.ad(AdObject.self, configuration) { [weak self] ad, error in
                guard let ad = ad, error == nil else {
                    response(.failure(.noBid))
                    return
                }
                                
                self?.response = response
                
                ad.controller = UIApplication.shared.bd.topViewcontroller
                ad.delegate = self
                ad.loadAd()
            }
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
    }
}
