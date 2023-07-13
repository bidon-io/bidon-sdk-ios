//
//  DirectDemandProviderWrapper.swift
//  Bidon
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation


final class DirectDemandProviderWrapper<W>: DemandProviderWrapper<W>, DirectDemandProvider {
    private let _load: (String, @escaping DemandProviderResponse) -> ()
    
    override init(_ wrapped: W) throws {
        guard let _wrapped = wrapped as? (any DirectDemandProvider) else { throw SdkError.internalInconsistency }
        
        _load = { _wrapped.load($0, response: $1) }
        
        try super.init(wrapped)
    }
    
    func load(_ adUnitId: String, response: @escaping DemandProviderResponse) {
        _load(adUnitId, response)
    }
}
