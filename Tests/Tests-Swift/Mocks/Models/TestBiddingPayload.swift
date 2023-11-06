//
//  TestBiddingPyload.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 06.11.2023.
//

import Foundation


struct TestBiddingPayload: Codable, Equatable {
    var payload: String = UUID().uuidString
}
