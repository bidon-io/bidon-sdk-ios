//
//  BidMachineAdUnit.swift
//  BidonAdapterBidMachine
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation


struct BidMachineAdUnitExtras: Decodable {
    let customParameters: [String: String]?
    let placements: [String: String]?
    let placement: String?
    let bcat: [String]?
    let badv: [String]?
    let bapps: [String]?
}
