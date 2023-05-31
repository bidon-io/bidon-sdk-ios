//
//  BidMachineBiddingDemandProvider.swift
//  BidonAdapterBidMachine
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation
import UIKit
import BidMachine
import BidMachineApiCore
import Bidon


fileprivate struct BidMachineBiddingContextEncoder: BiddingContextEncoder {
    let token: String

    init(token: String) {
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case token
    }

    func encodeBiddingContext(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
    }
}


class BidMachineBiddingDemandProvider<AdObject: BidMachineAdProtocol>: BidMachineBaseDemandProvider<AdObject>, BiddingDemandProvider {
    
    func fetchBiddingContext(response: @escaping BiddingContextResponse) {
        guard let token = BidMachineSdk.shared.token else {
            response(.failure(.unscpecifiedException))
            return
        }
        
        let encoder = BidMachineBiddingContextEncoder(token: token)
        response(.success(encoder))
    }
}
