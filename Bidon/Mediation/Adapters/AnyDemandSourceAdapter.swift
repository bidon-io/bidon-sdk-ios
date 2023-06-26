//
//  AnyAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation


struct MediationMode: OptionSet {
    let rawValue: UInt
    
    static let classic = MediationMode(rawValue: 1 << 0)
    static let programmatic = MediationMode(rawValue: 1 << 1)
    static let bidding = MediationMode(rawValue: 1 << 2)
    
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    fileprivate init<Provider: DemandProvider>(from provider: Provider) {
        var result: MediationMode = []
        
        if provider is any DirectDemandProvider {
            result.insert(.classic)
        }
        
        if provider is any ProgrammaticDemandProvider {
            result.insert(.programmatic)
        }
        
        if provider is any BiddingDemandProvider {
            result.insert(.bidding)
        }
        
        self = result
    }
}


struct AnyDemandSourceAdapter<DemandProviderType: DemandProvider>: Adapter, Hashable {
    var identifier: String
    var name: String
    var adapterVersion: String
    var sdkVersion: String
    var provider: DemandProviderType
    var mode: MediationMode
    
    init(
        adapter: Adapter,
        provider: DemandProviderType
    ) {
        self.identifier = adapter.identifier
        self.name = adapter.name
        self.adapterVersion = adapter.adapterVersion
        self.sdkVersion = adapter.sdkVersion
        self.provider = provider
        self.mode = MediationMode(from: provider)
    }
    
    init() {
        fatalError("AnyDemandSourceAdapter can't be created through default initializer")
    }
    
    static func == (
        lhs: AnyDemandSourceAdapter<DemandProviderType>,
        rhs: AnyDemandSourceAdapter<DemandProviderType>
    ) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.provider.self === rhs.provider.self
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}


extension AnyDemandSourceAdapter: CustomStringConvertible {
    var description: String {
        return "\(name) ('\(identifier)')"
    }
}
