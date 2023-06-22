//
//  AuctionContextMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation

@testable import Bidon


final class AuctionContextMock: AuctionContext {
    typealias DemandProviderType = DemandProviderMock
    typealias AuctionRequestBuilderType = AuctionRequestBuilderMock
    typealias BidRequestBuilderType = BidRequestBuilderMock
    typealias ImpressionRequestBuilderType = ImpressionRequestBuilderMock
    typealias LossRequestBuilderType = LossRequestBuilderMock

    var invokedAdTypeGetter = false
    var invokedAdTypeGetterCount = 0
    var stubbedAdType: AdType!

    var adType: AdType {
        invokedAdTypeGetter = true
        invokedAdTypeGetterCount += 1
        return stubbedAdType
    }
}


