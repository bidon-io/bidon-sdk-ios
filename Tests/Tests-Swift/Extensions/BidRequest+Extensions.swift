//
//  BidRequest.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 27.07.2023.
//

import Foundation


@testable import Bidon


extension BidRequest.ResponseBody {
    init?(raw: Any) {
        guard
            let data = try? JSONSerialization.data(withJSONObject: raw),
            let response = try? JSONDecoder().decode(Self.self, from: data)
        else { return nil }
        
        self = response
    }
}

