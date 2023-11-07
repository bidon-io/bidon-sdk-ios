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
    public var networkName: String { AmazonDemandSourceAdapter.identifier }
    public var dsp: String? { nil }
}


class AmazonBiddingDemandProvider<Dispatcher: DTBAdDispatcher>: NSObject, BiddingDemandProvider, DTBAdCallback {
    typealias DemandAdType = Dispatcher
   
    struct BiddingResponse: Codable {
        var slotUuid: String
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    private lazy var loader = DTBAdLoader()
    private lazy var adResponses = Set<DTBAdResponse>()
    
    private var tokenResponse: ((Result<AmazonBiddingToken, MediationError>) -> ())?
    
    func collectBiddingToken(
        adUnitExtras: AmazonAdUnitExtras,
        response: @escaping (Result<AmazonBiddingToken, MediationError>) -> ()
    ) {
        guard let adSize = adSize(adUnitExtras) else {
            response(.failure(.noAppropriateAdUnitId))
            return
        }
        
        loader.setAdSizes([adSize])
        
        self.tokenResponse = response
        
        loader.loadAd(self)
    }
    
    func load(
        payload: AmazonBiddingPayload,
        adUnitExtras: AmazonAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let adResponse = adResponses.first(where: { $0.adSize()?.slotUUID == adUnitExtras.slotUuid })
        else {
            response(.failure(.noAppropriateAdUnitId))
            return
        }
        
        fill(adResponse, response: response)
    }

    
    func onSuccess(_ adResponse: DTBAdResponse!) {
        adResponses.insert(adResponse)
        guard let token = AmazonBiddingToken(response: adResponse) else {
            tokenResponse?(.failure(.unscpecifiedException))
            return
        }
        
        tokenResponse?(.success(token))
    }
    
    func onFailure(_ error: DTBAdError) {
        tokenResponse?(.failure(MediationError(error: error)))
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
