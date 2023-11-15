//
//  ServerBidModel.swift
//  Bidon
//
//  Created by Stas Kochkin on 06.11.2023.
//

import Foundation


struct ServerBidModel: Decodable, ServerBid {
    enum CodingKeys: String, CodingKey {
        case id
        case impressionId = "impId"
        case winNoticeUrl = "nurl"
        case billingNoticeUrl = "burl"
        case lossNoticeUrl = "lurl"
        case payload = "ext"
        case adUnit
        case price
    }
    
    var id: String
    var impressionId: String
    var winNoticeUrl: String?
    var billingNoticeUrl: String?
    var lossNoticeUrl: String?
    var adUnit: AdUnitModel
    var price: Price
    var payload: Decoder
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        impressionId = try container.decode(String.self, forKey: .impressionId)
        winNoticeUrl = try container.decodeIfPresent(String.self, forKey: .winNoticeUrl)
        lossNoticeUrl = try container.decodeIfPresent(String.self, forKey: .lossNoticeUrl)
        adUnit = try container.decode(AdUnitModel.self, forKey: .adUnit)
        price = try container.decode(Price.self, forKey: .price)
        payload = try container.superDecoder(forKey: .payload)
    }
    
    static func == (
        lhs: ServerBidModel,
        rhs: ServerBidModel
    ) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
