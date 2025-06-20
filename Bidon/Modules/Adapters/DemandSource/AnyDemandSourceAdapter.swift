//
//  AnyAdapter.swift
//  Bidon
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation


struct AnyDemandSourceAdapterBidType: OptionSet {
    let rawValue: UInt

    static let direct = AnyDemandSourceAdapterBidType(rawValue: 1 << 0)
    static let bidding = AnyDemandSourceAdapterBidType(rawValue: 1 << 1)

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    fileprivate init<Provider: DemandProvider>(from provider: Provider) {
        var result: AnyDemandSourceAdapterBidType = []

        if provider is any DirectDemandProvider {
            result.insert(.direct)
        }

        if provider is any BiddingDemandProvider {
            result.insert(.bidding)
        }

        self = result
    }
}


struct AnyDemandSourceAdapter<DemandProviderType: DemandProvider>: Adapter, Hashable {
    var demandId: String
    var name: String
    var adapterVersion: String
    var sdkVersion: String
    var provider: DemandProviderType
    var supportedTypes: AnyDemandSourceAdapterBidType

    init(
        adapter: Adapter,
        provider: DemandProviderType
    ) {
        self.demandId = adapter.demandId
        self.name = adapter.name
        self.adapterVersion = adapter.adapterVersion
        self.sdkVersion = adapter.sdkVersion
        self.provider = provider
        self.supportedTypes = AnyDemandSourceAdapterBidType(from: provider)
    }

    init() {
        fatalError("AnyDemandSourceAdapter can't be created through default initializer")
    }

    static func == (
        lhs: AnyDemandSourceAdapter<DemandProviderType>,
        rhs: AnyDemandSourceAdapter<DemandProviderType>
    ) -> Bool {
        return lhs.demandId == rhs.demandId && lhs.provider.self === rhs.provider.self
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(demandId)
    }
}


extension AnyDemandSourceAdapter: CustomStringConvertible {
    var description: String {
        return "\(name) ('\(demandId)')"
    }
}
