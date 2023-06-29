//
//  AdapterMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation

@testable import Bidon


class AdapterMock: Adapter {
    required init() {}

    var stubbedIdentifier: String! = ""

    var identifier: String {
        return stubbedIdentifier
    }

    var stubbedName: String! = ""

    var name: String {
        return stubbedName
    }

    var stubbedAdapterVersion: String! = ""

    var adapterVersion: String {
        return stubbedAdapterVersion
    }

    var stubbedSdkVersion: String! = ""

    var sdkVersion: String {
        return stubbedSdkVersion
    }
    
    var stubbedProvider: DemandProviderMock!
    
    convenience init<T: DemandProviderMockBuildable>(
        id: String,
        provider: T.Type,
        build: ((T.Builder) -> ())? = nil
    ) {
        self.init()
        self.stubbedName = "Mock Adapter #" + id
        self.stubbedIdentifier = id
        self.stubbedSdkVersion = "0.0.0"
        self.stubbedAdapterVersion = "0"
        self.stubbedProvider = T { builder in
            builder.withDemandId(id)
            build?(builder)
        }
    }
}
