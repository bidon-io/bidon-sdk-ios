//
//  BiddingDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation


public typealias BiddingContextEncoderResponse = (Result<Encodable, MediationError>) -> ()


public protocol BiddingDemandProvider: DemandProvider {
    func collectBiddingTokenEncoder(
        adUnitExtrasDecoders: [Decoder],
        response: @escaping BiddingContextEncoderResponse
    )
    
    func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    )
}
