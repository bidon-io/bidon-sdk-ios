//
//  DemandAdMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation

@testable import Bidon


final class DemandAdMock: DemandAd {
    var stubbedId: String! = ""

    var id: String {
        return stubbedId
    }

    var stubbedNetworkName: String! = ""

    var networkName: String {
        return stubbedNetworkName
    }

    var stubbedDsp: String!

    var dsp: String? {
        return stubbedDsp
    }

    var stubbedECPM: Price!

    var eCPM: Price {
        return stubbedECPM
    }

    var stubbedCurrency: Currency!

    var currency: Currency {
        return stubbedCurrency
    }
}
