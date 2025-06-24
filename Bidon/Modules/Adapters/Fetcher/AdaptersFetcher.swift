//
//  AdaptersFetcher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 27/05/2024.
//

import Foundation

class AdaptersFetcher<AdTypeContextType: AdTypeContext> {

    func adapters() -> [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>] {
        fatalError("Base AdaptersFetcher can't return adapters")
    }
}
