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

    private var handler: AmazonBiddingHandler?
        
    func collectBiddingToken(
        adUnitExtras: [AmazonAdUnitExtras],
        response: @escaping (Result<AmazonBiddingToken, MediationError>) -> ()
    ) {
        let adSizes = adUnitExtras.compactMap(adSize)
        handler = AmazonBiddingHandler(adSizes: adSizes)
        handler?.fetch(response: response)
    }
    
    func load(
        payload: AmazonBiddingPayload,
        adUnitExtras: AmazonAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let adResponse = handler?.response(for: adUnitExtras.slotUuid)
        else {
            response(.failure(.noAppropriateAdUnitId))
            return
        }
        
        fill(adResponse, response: response)
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
        case NO_FILL: self = .noFill
        case REQUEST_ERROR: self = .noBid
        default: self = .unscpecifiedException
        }
    }
}
