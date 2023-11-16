//
//  ProgrammaticDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public protocol ProgrammaticDemandProvider: DemandProvider {
    func bid(
        _ pricefloor: Price,
        response: @escaping DemandProviderResponse
    )
    
    func fill(
        ad: DemandAdType,
        response: @escaping DemandProviderResponse
    )
}


internal extension ProgrammaticDemandProvider {
    func fill(
        opaque ad: DemandAd,
        response: @escaping DemandProviderResponse
    ) {
        guard let ad = ad as? DemandAdType else {
            response(.failure(.unscpecifiedException))
            return
        }
        
        fill(ad: ad, response: response)
    }
}

