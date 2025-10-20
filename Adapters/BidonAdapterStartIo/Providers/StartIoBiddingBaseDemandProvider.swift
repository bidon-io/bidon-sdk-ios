//
//  StartIoBiddingBaseDemandProvider.swift
//  BidonAdapterStartIo
//

import Foundation
import Bidon
import StartApp


class StartIoBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: StartIoBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        if let bidToken = STAStartAppSDK.sharedInstance().biddingToken {
            response(.success(bidToken))
        } else {
            response(.failure(.unspecifiedException("Start.io has not provided bidding token")))
        }
    }

    func load(
        payload: StartIoBiddingResponse,
        adUnitExtras: StartIoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("StartIoBiddingBaseDemandProvider is unable to prepare bid")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}


