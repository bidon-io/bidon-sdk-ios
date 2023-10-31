//
//  ParameterizedBiddingDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


public protocol ParameterizedBiddingDemandProvider: BiddingDemandProvider {
    associatedtype BiddingToken: Encodable
    associatedtype BiddingPayload: Decodable
    associatedtype AdUnitExtras: Decodable
    
    func collectBiddingToken(
        response: @escaping (Result<BiddingToken, MediationError>) -> ()
    )
    
    func load(
        payload: BiddingPayload,
        adUnitExtras: AdUnitExtras?,
        response: @escaping DemandProviderResponse
    )
}


extension ParameterizedBiddingDemandProvider {
    public func collectBiddingTokenEncoder(response: @escaping BiddingContextEncoderResponse) {
        collectBiddingToken { result in
            switch result {
            case .failure(let error):
                response(.failure(error))
            case .success(let context):
                response(.success(context))
            }
        }
    }
    
    public func load(
        payloadDecoder: Decoder,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    ) {
        var payload: BiddingPayload?
        var adUnitExtas: AdUnitExtras?
        
        do {
            payload = try BiddingPayload(from: payloadDecoder)
            adUnitExtas = try adUnitExtrasDecoder.map { try AdUnitExtras(from: $0) }
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
        
        guard let payload = payload else { return }
        
        load(
            payload: payload,
            adUnitExtras: adUnitExtas,
            response: response
        )
    }
}
