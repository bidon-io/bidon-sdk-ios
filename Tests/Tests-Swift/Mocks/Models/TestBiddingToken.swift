//
//  TestBiddingToken.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 06.11.2023.
//

import Foundation


struct TestBiddingToken: Codable, Equatable {
    var token: String = UUID().uuidString
}
