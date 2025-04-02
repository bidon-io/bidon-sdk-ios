//
//  MintegralBiddingToken.swift
//  BidonAdapterMintegral
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation


struct MintegralBiddingToken: Codable {
    var buyerUID: String
    
    enum CodingKeys: String, CodingKey {
        case buyerUID = "token"
    }
}
