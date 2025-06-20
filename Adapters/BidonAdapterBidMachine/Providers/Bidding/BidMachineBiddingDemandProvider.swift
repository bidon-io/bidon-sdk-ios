//
//  BidMachineBiddingDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import Bidon

class BidMachineBiddingDemandProvider<AdObject>: BidMachineBaseDemandProvider<AdObject>, BiddingDemandProvider
where AdObject: BidMachineAdProtocol {
    struct BiddingResponse: Codable {
        var payload: String
    }

    func collectBiddingToken(
        biddingTokenExtras: BidMachineAdUnitExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {

        BidMachineSdk.shared.token(with: placementFormat) { token in
            guard let token else {
                response(.failure(.unspecifiedException("BidMachine has not provided bidding token")))
                return
            }
            response(.success(token))
        }
    }

    func load(
        payload: BidMachineBiddingPayload,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let configuration = try BidMachineSdk.shared.requestConfiguration(placementFormat)
            var parameters = adUnitExtras.customParameters ?? [String: String]()
            parameters["mediation_mode"] = "bidon"

            configuration.populate { builder in
                builder.withPayload(payload.payload)
                builder.withCustomParameters(parameters)
            }

            BidMachineSdk.shared.ad(AdObject.self, configuration) { [weak self] ad, error in
                guard let self = self else { return }

                guard let ad = ad, error == nil else {
                    response(.failure(.noBid(error?.localizedDescription)))
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
