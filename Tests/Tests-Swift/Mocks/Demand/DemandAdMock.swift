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

    var stubbedPrice: Price!

    var price: Price {
        return stubbedPrice
    }
}
