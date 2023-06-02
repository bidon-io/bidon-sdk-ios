//
//  AuctionRoundModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AuctionRoundModel: Decodable, AuctionRound {
    var id: String
    var timeout: TimeInterval
    var demands: [String]
    var bidding: [String]
    
    enum CodingKeys: CodingKey {
        case id
        case timeout
        case demands
        case bidding
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        self.demands = try container.decodeIfPresent([String].self, forKey: .demands) ?? []
        self.bidding = try container.decodeIfPresent([String].self, forKey: .bidding) ?? []
    }
}

