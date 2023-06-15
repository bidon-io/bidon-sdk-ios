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
    var gender: String
    var age: Int
    var gameLevel: Int
    var totalInAppsAmount: Double
    var isPaying: Bool
    var customAttributes: [String: Any]
    
    enum CodingKeys: CodingKey {
        case id
        case ext
    }
    
    init(_ segment: Segment) {
        self.id = segment.id
        self.gender = segment.gender.description.uppercased()
        self.age = segment.age
        self.gameLevel = segment.level
        self.totalInAppsAmount = segment.inAppAmount
        self.isPaying = segment.isPaid
        self.customAttributes = segment.customAttributes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        
        let ext: [String: Any] = [
            "age": age,
            "gender": gender,
            "is_paying": isPaying,
            "total_in_apps_amount": totalInAppsAmount,
            "game_level": gameLevel,
            "custom_attributes": customAttributes
        ]
        
        let extData = try JSONSerialization.data(withJSONObject: ext)
        let extString = String(data: extData, encoding: .utf8)
        try container.encode(extString, forKey: .ext)
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
