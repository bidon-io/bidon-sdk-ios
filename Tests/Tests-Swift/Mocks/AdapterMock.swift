//
//  AdapterMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation

@testable import Bidon


class AdapterMock: Adapter {
    required init() {}

    var stubbedDemandId: String! = ""

    var demandId: String {
        return stubbedDemandId
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
        demandId: String,
        provider: T.Type,
        build: ((T.Builder) -> ())? = nil
    ) {
        self.init()
        self.stubbedName = "Mock Adapter #" + demandId
        self.stubbedDemandId = demandId
        self.stubbedSdkVersion = "0.0.0"
        self.stubbedAdapterVersion = "0"
        self.stubbedProvider = T { builder in
            build?(builder)
        }
    }
}
