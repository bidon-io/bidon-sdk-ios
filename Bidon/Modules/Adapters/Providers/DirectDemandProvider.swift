//
//  DirectDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public protocol GenericDirectDemandProvider: DemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    )
}


public protocol DirectDemandProvider: GenericDirectDemandProvider {
    associatedtype AdUnitExtras: Decodable
    
    func load(
        pricefloor: Price,
        adUnitExtras: AdUnitExtras,
        response: @escaping DemandProviderResponse
    )
}


extension DirectDemandProvider {
    public func load(
        pricefloor: Price,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    ) {
        do {
            let adUnitExtas = try AdUnitExtras(from: adUnitExtrasDecoder)
            
            load(
                pricefloor: pricefloor,
                adUnitExtras: adUnitExtas,
                response: response
            )
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
    }
}

final class DirectDemandProviderWrapper<W>: DemandProviderWrapper<W>, GenericDirectDemandProvider {
    private let _load: (Price, Decoder, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any GenericDirectDemandProvider)
        else { throw SdkError.internalInconsistency }
        
        _load = { _wrapped.load(pricefloor: $0, adUnitExtrasDecoder: $1, response: $2) }
        
        try super.init(wrapped)
    }
    
    func load(
        pricefloor: Price,
        adUnitExtrasDecoder: Decoder,
        response: @escaping DemandProviderResponse
    ) {
        _load(pricefloor, adUnitExtrasDecoder, response)
    }
}
