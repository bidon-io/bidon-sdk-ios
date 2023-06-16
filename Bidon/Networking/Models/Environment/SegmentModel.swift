//
//  SegmentModel.swift
//  Bidon
//
//  Created by Stas Kochkin on 15.06.2023.
//

import Foundation


struct SegmentResponseModel: Decodable, SegmentResponse {
    var id: String
}


struct SegmentModel: Encodable {
    var id: String?
    var gender: String?
    var age: Int?
    var gameLevel: Int?
    var totalInAppsAmount: Double?
    var isPaying: Bool?
    var customAttributes: [String: Any]?
    
    var ext: [String: Any] {
        var ext: [String: Any] = [:]
        if let age = age {
            ext["age"] = age
        }
        if let gender = gender {
            ext["gender"] = gender
        }
        if let isPaying = isPaying {
            ext["is_paying"] = isPaying
        }
        if let totalInAppsAmount = totalInAppsAmount {
            ext["total_in_apps_amount"] = totalInAppsAmount
        }
        if let gameLevel = gameLevel {
            ext["game_level"] = gameLevel
        }
        if let customAttributes = customAttributes {
            ext["custom_attributes"] = customAttributes
        }
        return ext
    }
    
    enum CodingKeys: CodingKey {
        case id
        case ext
    }
    
    init(_ segment: SegmentManager) {
        self.id = segment.id
        self.gender = segment._gender?.description.uppercased()
        self.age = segment._age
        self.gameLevel = segment._level
        self.totalInAppsAmount = segment._inAppAmount
        self.isPaying = segment._isPaid
        self.customAttributes = segment._customAttributes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        
        if !ext.isEmpty {
            let extData = try JSONSerialization.data(withJSONObject: ext)
            let extString = String(data: extData, encoding: .utf8)
            try container.encode(extString, forKey: .ext)
        }
    }
}


extension Gender: CustomStringConvertible {
    public var description: String {
        switch self {
        case .other: return "Other"
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}
