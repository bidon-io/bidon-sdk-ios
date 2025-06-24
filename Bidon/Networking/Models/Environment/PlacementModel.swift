//
//  PlacementModel.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 23/05/2024.
//

import Foundation

struct PlacementModel: Codable {
    struct Reward: Codable {
        let title: String
        let value: Price
    }

    struct Capping: Codable {
        let setting: String
        let value: Price
    }

    let id: String
    let reward: Reward
    let capping: Capping
}
