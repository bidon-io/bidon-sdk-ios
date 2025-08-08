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
        auctionKey: String?,
        biddingTokenExtras: BidMachineAdUnitExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let key = auctionKey.flatMap { $0.isEmpty ? nil : $0 } ?? "default"
        let placementId = biddingTokenExtras.placements?[key] as? String
        let placement = try? BidMachineSdk.shared.placement(from: placementFormat) {
            if let placementId {
                $0.withPlacementId(placementId)
            }
            $0.withCustomParameters([String: Any]())
        }
        guard let placement else {
            response(.failure(.unspecifiedException("No placement to generate bidding token")))
            return
        }
        BidMachineSdk.shared.token(placement: placement) { token in
            guard let token else {
                response(.failure(.unspecifiedException("BidMachine has not provided bidding token")))
                return
            }
            response(.success(token))
        }
    }

    func collectBiddingToken(biddingTokenExtras: BidMachineAdUnitExtras, response: @escaping (Result<String, MediationError>) -> ()) {

    }

    func load(
        payload: BidMachineBiddingPayload,
        adUnitExtras: BidMachineAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("BidMachineBiddingDemandProvider is not able to create ad object")
    }
}
