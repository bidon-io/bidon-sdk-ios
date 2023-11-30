//
//  AdViewStatisticsRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.11.2023.
//

import Foundation


final class AdViewStatisticsRequestBuilder: BaseStatisticRequestBuilder<BannerAdTypeContext> {
    override func transform<T>(
        report: T,
        configuration: AuctionConfiguration
    ) -> MediationAttemptReportCodableModel where T : MediationAttemptReport {
        return MediationAttemptReportCodableModel(
            report,
            auctionConfiguration: configuration,
            banner: BannerAdTypeContextModel(context)
        )
    }
}
