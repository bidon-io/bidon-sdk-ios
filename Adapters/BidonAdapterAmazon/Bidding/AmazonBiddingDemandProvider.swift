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


class AmazonBiddingDemandProvider<Dispatcher: DTBAdDispatcher>: NSObject, ParameterizedBiddingDemandProvider {
    typealias DemandAdType = Dispatcher
    
    struct BiddingSlotData: Codable {
        var slotUuid: String
        var pricePoint: String
    }
    
    struct BiddingContext: Codable {
        var slots: [BiddingSlotData]
    }
    
    struct BiddingResponse: Codable {
        var slotUuid: String
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    private let adSizes: [DTBAdSize]
    
    private lazy var loader: DTBAdLoader = {
        let loader = DTBAdLoader()
        loader.setAdSizes(adSizes)
        return loader
    }()
    
    init(adSizes: [DTBAdSize]) {
        self.adSizes = adSizes
        super.init()
    }
    
    func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        let handler = AmazonBiddingContextCallbackHandler(response: response)
        loader.loadAd(handler)
    }
    
    func prepareBid(data: BiddingResponse, response: @escaping DemandProviderResponse) {
        
    }
    
    func notify(ad: Dispatcher, event: AuctionEvent) {}
}


extension AmazonBiddingDemandProvider {
    final class AmazonBiddingContextCallbackHandler: NSObject, DTBAdCallback {
        private var response: ((Result<BiddingContext, MediationError>) -> ())?
        
        init(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
            self.response = response
            super.init()
        }
        
        func onSuccess(_ adResponse: DTBAdResponse!) {
            let context = AmazonBiddingDemandProvider.BiddingContext(slots: [])
            response?(.success(context))
            response = nil
        }
        
        func onFailure(_ error: DTBAdError) {
            response?(.failure(MediationError(error: error)))
            response = nil
        }
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
