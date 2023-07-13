//
//  BiddingDemandProviderWrapper.swift
//  Bidon
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation


final class BiddingDemandProviderWrapper<W>: DemandProviderWrapper<W>, BiddingDemandProvider {
    private let _fetchBiddingContextEncoder: (@escaping BiddingContextEncoderResponse) -> ()
    private let _prepareBid: (String, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any BiddingDemandProvider) else { throw SdkError.internalInconsistency }
        
        _fetchBiddingContextEncoder = { _wrapped.fetchBiddingContextEncoder(response: $0) }
        _prepareBid = { _wrapped.prepareBid(with: $0, response: $1) }
        
        try super.init(wrapped)
    }
    
    func fetchBiddingContextEncoder(response: @escaping BiddingContextEncoderResponse) {
        _fetchBiddingContextEncoder(response)
    }
    
    func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        _prepareBid(payload, response)
    }
}

