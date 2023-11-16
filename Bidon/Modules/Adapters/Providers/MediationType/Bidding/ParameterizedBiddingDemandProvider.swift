//
//  ParameterizedBiddingDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


struct GenericBiddingContextEncoder<BiddingContext: Encodable>: BiddingContextEncoder {
    var context: BiddingContext
    
    func encodeBiddingContext(to encoder: Encoder) throws {
        try context.encode(to: encoder)
    }
}


public protocol ParameterizedBiddingDemandProvider: BiddingDemandProvider {
    associatedtype BiddingContext: Encodable
    associatedtype BiddingResponse: Decodable
    
    func fetchBiddingContext(
        response: @escaping (Result<BiddingContext, MediationError>) -> ()
    )
    
    func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    )
}


extension ParameterizedBiddingDemandProvider {
    public func fetchBiddingContextEncoder(response: @escaping BiddingContextEncoderResponse) {
        fetchBiddingContext { result in
            switch result {
            case .failure(let error):
                response(.failure(error))
            case .success(let context):
                let encoder = GenericBiddingContextEncoder(context: context)
                response(.success(encoder))
            }
        }
    }
    
    public func prepareBid(
        from decoder: Decoder,
        response: @escaping DemandProviderResponse
    ) {
        var data: BiddingResponse?
        do {
            data = try BiddingResponse(from: decoder)
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
        
        guard let data = data else { return }
        
        prepareBid(
            data: data,
            response: response
        )
    }
}
