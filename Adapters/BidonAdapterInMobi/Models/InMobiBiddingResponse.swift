//
//  InMobiBiddingResponse.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import Bidon


struct InMobiBiddingResponse: Decodable {
    var payload: String

    enum CodingKeys: String, CodingKey {
        case payload
    }

    init(payload: String) {
        self.payload = payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let token = try? container.decode(String.self, forKey: .payload) {
            self.payload = token
            return
        }

        if let anyValue = try? container.decode(BidonDecodable.self, forKey: .payload) {
            if let str = anyValue.stringValue {
                self.payload = str
                return
            }
            if let nestedDict = anyValue.value as? [String: Any] {
                if JSONSerialization.isValidJSONObject(nestedDict),
                   let data = try? JSONSerialization.data(withJSONObject: nestedDict),
                   let json = String(data: data, encoding: .utf8) {
                    self.payload = json
                    return
                }
            }
        }

        throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode InMobi payload"))
    }
}
