//
//  VAuctionController.swift
//  Bidon
//
//  Created by Dzmitry on 10/03/2026.
//

import Foundation

final class VAuctionController<AdTypeContextType: AdTypeContext>: ZhenyaAuctionController<AdTypeContextType> {
    func finish() {
        finishAuction()
    }
}
