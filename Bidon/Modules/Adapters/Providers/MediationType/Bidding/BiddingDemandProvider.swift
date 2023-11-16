//
//  BiddingDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation


public protocol BiddingContextEncoder {
    func encodeBiddingContext(to encoder: Encoder) throws
}


public typealias BiddingContextEncoderResponse = (Result<BiddingContextEncoder, MediationError>) -> ()


public protocol BiddingDemandProvider: DemandProvider {
    func fetchBiddingContextEncoder(response: @escaping BiddingContextEncoderResponse)
    
    func prepareBid(from decoder: Decoder, response: @escaping DemandProviderResponse)
}
