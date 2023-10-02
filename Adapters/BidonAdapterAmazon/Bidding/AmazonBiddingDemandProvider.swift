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
    typealias BiddingContext = AmazonBiddingSlots
   
    struct BiddingResponse: Codable {
        var slotUuid: String
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    private let adSizes: [DTBAdSize]
    private lazy var biddingHandler = AmazonBiddingHandler(adSizes: adSizes)
    
    init(adSizes: [DTBAdSize]) {
        self.adSizes = adSizes
        super.init()
    }
    
    final func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        biddingHandler.fetch(response: response)
    }
    
    final func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        guard let data = biddingHandler.response(for: data.slotUuid) else {
            response(.failure(.noFill))
            return
        }
        
        fill(data, response: response)
    }
    
    final func notify(ad: Dispatcher, event: AuctionEvent) {}
    
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
