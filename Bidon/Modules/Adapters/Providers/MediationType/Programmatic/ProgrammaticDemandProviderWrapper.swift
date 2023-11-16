//
//  ProgrammaticDemandProviderWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation


final class ProgrammaticDemandProviderWrapper<W>: DemandProviderWrapper<W>, ProgrammaticDemandProvider {
    private let _bid: (Price, @escaping DemandProviderResponse) -> ()
    private let _fill: (DemandAd, @escaping DemandProviderResponse) -> ()

    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any ProgrammaticDemandProvider) else { throw SdkError.internalInconsistency }
        
        _bid = { _wrapped.bid($0, response: $1) }
        _fill = { _wrapped.fill(opaque: $0, response: $1) }

        try super.init(wrapped)
    }
    
    
    func bid(_ pricefloor: Price, response: @escaping DemandProviderResponse) {
        _bid(pricefloor, response)
    }
    
    func fill(ad: DemandAd, response: @escaping DemandProviderResponse) {
        _fill(ad, response)
    }
}
