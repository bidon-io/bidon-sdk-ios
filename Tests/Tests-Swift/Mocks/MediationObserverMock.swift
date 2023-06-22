//
//  MediationObserverMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation

@testable import Bidon


final class MediationObserverMock: MediationObserver {
    typealias MediationAttemptReportType = MediationAttemptReportModel
    
    var invokedAuctionIdGetter = false
    var invokedAuctionIdGetterCount = 0
    var stubbedAuctionId: String! = ""

    var auctionId: String {
        invokedAuctionIdGetter = true
        invokedAuctionIdGetterCount += 1
        return stubbedAuctionId
    }

    var invokedAuctionConfigurationIdGetter = false
    var invokedAuctionConfigurationIdGetterCount = 0
    var stubbedAuctionConfigurationId: Int! = 0

    var auctionConfigurationId: Int {
        invokedAuctionConfigurationIdGetter = true
        invokedAuctionConfigurationIdGetterCount += 1
        return stubbedAuctionConfigurationId
    }

    var invokedAdTypeGetter = false
    var invokedAdTypeGetterCount = 0
    var stubbedAdType: AdType!

    var adType: AdType {
        invokedAdTypeGetter = true
        invokedAdTypeGetterCount += 1
        return stubbedAdType
    }

    var invokedReportGetter = false
    var invokedReportGetterCount = 0
    var stubbedReport: MediationAttemptReportType!

    var report: MediationAttemptReportType {
        invokedReportGetter = true
        invokedReportGetterCount += 1
        return stubbedReport
    }

    var invokedLog = false
    var invokedLogCount = 0
    var invokedLogParameters: (event: Any, Void)?
    var invokedLogParametersList = [(event: Any, Void)]()

    func log<EventType: MediationEvent>(_ event: EventType) {
        invokedLog = true
        invokedLogCount += 1
        invokedLogParameters = (event, ())
        invokedLogParametersList.append((event, ()))
    }
}
