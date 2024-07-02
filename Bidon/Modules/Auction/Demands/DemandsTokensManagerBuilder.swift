//
//  DemandsTokensManagerBuilder.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 27/05/2024.
//

import Foundation

final class DemandsTokensManagerBuilder<AdTypeContextType: AdTypeContext> {
    
    private(set) var adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]!
    private(set) var demands: [String]!
    private(set) var timeout: TimeInterval!
    
    required init() {}
        
    @discardableResult
    func withDemands(_ demands: [String]) -> Self {
        self.demands = demands
        return self
    }
    
    @discardableResult
    func withAdapters(_ adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]) -> Self {
        self.adapters = adapters
        return self
    }
    
    @discardableResult
    func withTimeout(_ timeout: TimeInterval) -> Self {
        self.timeout = timeout
        return self
    }
}
