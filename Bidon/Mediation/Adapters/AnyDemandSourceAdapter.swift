//
//  AnyAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation


struct AnyDemandSourceAdapter<DemandProviderType: DemandProvider>: Adapter, Hashable {
    var identifier: String
    var name: String
    var adapterVersion: String
    var sdkVersion: String
    var provider: DemandProviderType
    
    init(
        adapter: Adapter,
        provider: DemandProviderType
    ) {
        self.identifier = adapter.identifier
        self.name = adapter.name
        self.adapterVersion = adapter.adapterVersion
        self.sdkVersion = adapter.sdkVersion
        self.provider = provider
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


extension AnyDemandSourceAdapter {
    var isBiddingAdapter: Bool {
        return provider is any BiddingDemandProvider
    }
}

