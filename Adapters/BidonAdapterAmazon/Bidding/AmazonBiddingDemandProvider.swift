//
//  AmazonBiddingDemandProvider.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 22.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


extension DTBAdDispatcher: DemandAd {
    public var id: String { String(hash) }
}


class AmazonBiddingDemandProvider<Dispatcher: DTBAdDispatcher>: NSObject, BiddingDemandProvider {
    typealias DemandAdType = Dispatcher

    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: AmazonBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        fatalError("AmazonBiddingDemandProvider does not implement collectBiddingToken")
    }

    func load(
        payload: AmazonBiddingPayload,
        adUnitExtras: AmazonAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("AmazonBiddingDemandProvider does not implement method load")
    }

    final func notify(ad: Dispatcher, event: DemandProviderEvent) {}

    open func adSize(_ extras: AmazonAdUnitExtras) -> DTBAdSize? {
        return extras.adSize()
    }

    open func fill(
        _ data: DTBAdResponse,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("AmazonBiddingDemandProvider does not implement fill(_:response:)")
    }
}

extension Bidon.MediationError {
    init(error: DTBAdError) {
        switch error {
        case NETWORK_ERROR, NETWORK_TIMEOUT: self = .networkError
        case NO_FILL: self = .noFill(nil)
        case REQUEST_ERROR: self = .unspecifiedException("Request Error")
        default: self = .unspecifiedException("Unknown error")
        }
    }
}

extension Bidon.MediationError {
    init(_ error: DTBAdErrorCode) {
        switch error {
        case .SampleErrorCodeBadRequest:
            self = .unspecifiedException("Bad Request")
        case .SampleErrorCodeUnknown:
            self = .unspecifiedException("Unknown Error")
        case .SampleErrorCodeNetworkError:
            self = .networkError
        case .SampleErrorCodeNoInventory:
            self = .noFill(nil)
        @unknown default:
            self = .unspecifiedException("Unknown Error")
        }
    }
}
