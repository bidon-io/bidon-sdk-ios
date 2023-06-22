//
//  AuctionRoundMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation

@testable import Bidon


struct AuctionRoundMock: AuctionRound {
    var id: String
    var timeout: TimeInterval
    var demands: [String]
    var bidding: [String]
}
