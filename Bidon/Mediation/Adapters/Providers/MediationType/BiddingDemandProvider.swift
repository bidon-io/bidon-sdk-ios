//
//  BiddingDemandProvider.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation


public protocol BiddingContextEncoder {
    func encodeBiddingContext(to encoder: Encoder) throws
}


public typealias BiddingContextResponse = (Result<BiddingContextEncoder, MediationError>) -> ()


public protocol BiddingDemandProvider: DemandProvider {
    func fetchBiddingContext(response: @escaping BiddingContextResponse)
    
    func prepareBid(with payload: String, response: @escaping DemandProviderResponse)
}


final class BiddingDemandProviderWrapper<W>: DemandProviderWrapper<W>, BiddingDemandProvider {
    private let _fetchBiddingContext: (@escaping BiddingContextResponse) -> ()
    private let _prepareBid: (String, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any BiddingDemandProvider) else { throw SdkError.internalInconsistency }
        
        _fetchBiddingContext = { _wrapped.fetchBiddingContext(response: $0) }
        _prepareBid = { _wrapped.prepareBid(with: $0, response: $1) }
        
        try super.init(wrapped)
    }
    
    func fetchBiddingContext(response: @escaping BiddingContextResponse) {
        _fetchBiddingContext(response)
    }
    
    func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        _prepareBid(payload, response)
    }
}
