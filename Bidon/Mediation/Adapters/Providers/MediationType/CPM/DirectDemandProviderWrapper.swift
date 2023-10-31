//
//  DirectDemandProviderWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


final class DirectDemandProviderWrapper<W>: DemandProviderWrapper<W>, DirectDemandProvider {
    private let _load: (Price, Decoder?, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any DirectDemandProvider)
        else { throw SdkError.internalInconsistency }
        
        _load = { _wrapped.load(pricefloor: $0, adUnitExtrasDecoder: $1, response: $2) }
        
        try super.init(wrapped)
    }
    
    func load(
        pricefloor: Double,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    ) {
        
    }
}
