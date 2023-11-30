//
//  StatisticRequestBuilderMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 30.11.2023.
//

import Foundation

@testable import Bidon


final class StatisticBuilderMock: BaseStatisticRequestBuilder<AdTypeContextMock> {
    override func transform<T>(
        report: T,
        configuration: AuctionConfiguration
    ) -> MediationAttemptReportCodableModel where T : MediationAttemptReport {
        return MediationAttemptReportCodableModel(report, auctionConfiguration: configuration)
    }
}
