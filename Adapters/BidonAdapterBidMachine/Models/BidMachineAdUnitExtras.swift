//
//  BidMachineAdUnit.swift
//  BidonAdapterBidMachine
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation


struct BidMachineAdUnitExtras: Codable {
    let customParameters: [String: String]?
    let placements: [String: String]?
    let placement: String?
}
