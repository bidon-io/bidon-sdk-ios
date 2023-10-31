//
//  DirectDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public protocol DirectDemandProvider: DemandProvider {
    func load(
        pricefloor: Double,
        adUnitExtrasDecoder: Decoder?,
        response: @escaping DemandProviderResponse
    )
}
