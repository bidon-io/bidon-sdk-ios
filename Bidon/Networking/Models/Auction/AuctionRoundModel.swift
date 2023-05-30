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
}

