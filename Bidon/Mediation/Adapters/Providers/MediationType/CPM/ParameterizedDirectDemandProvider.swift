//
//  ParameterizedDirectDemandProvider.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.10.2023.
//

import Foundation


public protocol ParameterizedDirctDemandProvider: DirectDemandProvider {
    associatedtype AdUnitExtras: Decodable
    
    func load(
        pricefloor: Price,
        adUnitExtras: AdUnitExtras?,
        response: @escaping DemandProviderResponse
    )
}


extension ParameterizedDirctDemandProvider {
    public func load(
        pricefloor: Price,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    ) {
        var adUnitExtras: AdUnitExtras?
        
        do {
            adUnitExtras = try adUnitExtrasDecoder.map { try AdUnitExtras(from: $0) }
        } catch {
            response(.failure(.incorrectAdUnitId))
        }
        
        load(
            pricefloor: pricefloor,
            adUnitExtras: adUnitExtras,
            response: response
        )
    }
}
