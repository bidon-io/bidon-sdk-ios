//
//  BiddingDemandProviderWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


final class BiddingDemandProviderWrapper<W>: DemandProviderWrapper<W>, BiddingDemandProvider {
    private let _collectBiddingTokenEncoder: ([Decoder], @escaping BiddingContextEncoderResponse) -> ()
    private let _load: (Decoder, Decoder?, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any BiddingDemandProvider) 
        else { throw SdkError.internalInconsistency }
        
        _collectBiddingTokenEncoder = { _wrapped.collectBiddingTokenEncoder(adUnitExtrasDecoders: $0, response: $1) }
        _load = { _wrapped.load(payloadDecoder: $0, adUnitExtrasDecoder: $1, response: $2) }
        
        try super.init(wrapped)
    }
    
    func collectBiddingTokenEncoder(
        adUnitExtrasDecoders: [Decoder],
        response: @escaping BiddingContextEncoderResponse
    ) {
        _collectBiddingTokenEncoder(adUnitExtrasDecoders, response)
    }
    
    func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    ) {
       _load(payloadDecoder, adUnitExtrasDecoder, response)
    }
}

