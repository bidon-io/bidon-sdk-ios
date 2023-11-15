//
//  BidRequest.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 27.07.2023.
//

import Foundation


@testable import Bidon


extension BidRequest.ResponseBody {
    init(_ response: TestResponse) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(response)
        self = try! decoder.decode(Self.self, from: data)
    }
    
    init(bids: [TestServerBid]) {
        let response = TestResponse(bids: bids)
        self.init(response)
    }
}


struct TestServerBid: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case impId
        case price
        case adUnit
        case ext
    }
    
    var id: String = UUID().uuidString
    var impId: String = UUID().uuidString
    var price: Price
    var adUnit: TestAdUnit
    var ext: TestBiddingPayload
}


struct TestResponse: Codable {
    var bids: [TestServerBid]
}
