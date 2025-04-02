//
//  TestAdUnitExtras.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 06.11.2023.
//

import Foundation


@testable import Bidon


struct TestAdUnitExtras: Codable, Equatable {
    var extras: String = UUID().uuidString
    
    enum CodingKeys: String, CodingKey {
        case extras = "ext"
    }
}


struct TestAdUnit: Codable, AdUnit {
    typealias ExtrasType = TestAdUnitExtras
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case demandId = "demandId"
        case demandType = "bidType"
        case label
        case pricefloor
        case extras = "ext"
    }
    
    var uid: String
    var demandId: String
    var demandType: BidType
    var label: String
    var pricefloor: Price
    var extras: TestAdUnitExtras
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}


extension TestAdUnit {
    init(
        uid: String = UUID().uuidString,
        demandId: String,
        demandType: BidType,
        label: String = "Test Ad Unit",
        pricefloor: Price,
        extras: String
    ) {
        self.uid = uid
        self.demandId = demandId
        self.demandType = demandType
        self.label = label
        self.pricefloor = pricefloor
        self.extras = TestAdUnitExtras(extras: extras)
    }
    
    var adUnit: AdUnitModel {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
    
        let data = try! encoder.encode(self)
        return try! decoder.decode(AdUnitModel.self, from: data)
    }
}
