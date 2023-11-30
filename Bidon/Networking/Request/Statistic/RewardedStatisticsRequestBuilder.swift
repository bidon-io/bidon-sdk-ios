//
//  RewardedStatisticsRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.11.2023.
//

import Foundation


final class RewardedStatisticRequestBuilder: BaseStatisticRequestBuilder<RewardedAdTypeContext> {
    override func transform<T>(
        report: T,
        configuration: AuctionConfiguration
    ) -> MediationAttemptReportCodableModel where T : MediationAttemptReport {
        return MediationAttemptReportCodableModel(
            report,
            auctionConfiguration: configuration,
            rewarded: RewardedAdTypeContextModel(context)
        )
    }
}
