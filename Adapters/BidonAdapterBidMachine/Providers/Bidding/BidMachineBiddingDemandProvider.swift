//
//  BidMachineBiddingDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon



class BidMachineBiddingDemandProvider<AdObject>: BidMachineBaseDemandProvider<AdObject>, BiddingDemandProvider
where AdObject: BidMachineAdProtocol {
    struct BiddingResponse: Codable {
        var payload: String
    }
    
    func collectBiddingToken(
        adUnitExtras: [BidMachineAdUnitExtras],
        response: @escaping (Result<BidMachineBiddingToken, MediationError>) -> ()
    ) {
        guard let token = BidMachineSdk.shared.token else {
            response(.failure(.unscpecifiedException))
            return
        }
        
        response(.success(BidMachineBiddingToken(token: token)))
    }
    
    func load(
        payload: BidMachineBiddingPayload,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let configuration = try BidMachineSdk.shared.requestConfiguration(placementFormat)
            
            configuration.populate { builder in
                builder.withPayload(payload.payload)
                builder.withCustomParameters(["mediation_mode": "bidon"])
            }
            
            BidMachineSdk.shared.ad(AdObject.self, configuration) { [weak self] ad, error in
                guard let self = self else { return }
                
                guard let ad = ad, error == nil else {
                    response(.failure(.noBid))
                    return
                }
                                
                ad.controller = UIApplication.shared.bd.topViewcontroller
                ad.delegate = self
                
                self.response = response
                self.ad = ad
                
                ad.loadAd()
            }
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
    }
}
