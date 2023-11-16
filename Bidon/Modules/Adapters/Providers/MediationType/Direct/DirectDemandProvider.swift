//
//  DirectDemandProvider.swift
//  Bidon
//
//  Created by Bidon Team on 19.04.2023.
//

import Foundation


public protocol DirectDemandProvider: DemandProvider {
    func load(
        _ adUnitId: String,
        response: @escaping DemandProviderResponse
    )
}
