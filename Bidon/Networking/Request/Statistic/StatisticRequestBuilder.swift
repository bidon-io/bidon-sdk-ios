//
//  StatisticRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


final class StatisticRequestBuilder: BaseRequestBuilder {
    private(set) var stats: MediationAttemptReportCodableModel!
    
    var adType: AdType!
    
    @discardableResult
    func withMediationReport<T: MediationAttemptReport>(
        _ report: T,
        auctionConfiguration: AuctionConfiguration
    ) -> Self {
        self.stats = MediationAttemptReportCodableModel(
            report,
            auctionConfiguration: auctionConfiguration
        )
        return self
    }
    
    @discardableResult
    func withAdType(_ adType: AdType) -> Self {
        self.adType = adType
        return self
    }
}
