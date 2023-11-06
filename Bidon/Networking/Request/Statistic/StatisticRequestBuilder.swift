//
//  StatisticRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


final class StatisticRequestBuilder: BaseRequestBuilder {
    private(set) var stats: EncodableAuctionReportModel!
    
    var adType: AdType!
    
    @discardableResult
    func withMediationReport<T: AuctionReport>(_ report: T) -> Self {
        self.stats = EncodableAuctionReportModel(report)
        return self
    }
    
    @discardableResult
    func withAdType(_ adType: AdType) -> Self {
        self.adType = adType
        return self
    }
}
