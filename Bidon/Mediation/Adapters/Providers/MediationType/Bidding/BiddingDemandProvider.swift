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


public typealias BiddingContextEncoderResponse = (Result<BiddingContextEncoder, MediationError>) -> ()


public protocol BiddingDemandProvider: DemandProvider {
    func fetchBiddingContextEncoder(response: @escaping BiddingContextEncoderResponse)
    
    func prepareBid(with payload: String, response: @escaping DemandProviderResponse)
}
