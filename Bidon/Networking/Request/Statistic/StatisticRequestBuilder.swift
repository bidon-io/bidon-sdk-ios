//
//  StatisticRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol StatisticRequestBuilder: AdTypeContextRequestBuilder {
    var stats: MediationAttemptReportCodableModel { get }
    var route: Route { get }
    
    @discardableResult
    func withMediationReport<T: MediationAttemptReport>(
        _ report: T,
        auctionConfiguration: AuctionConfiguration
    ) -> Self
    
    init()
}


class BaseStatisticRequestBuilder<Context: AdTypeContext>: BaseRequestBuilder, StatisticRequestBuilder {
    private(set) var context: Context!
    
    var stats: MediationAttemptReportCodableModel { _stats }
    
    private var _stats: MediationAttemptReportCodableModel!

    var route: Route { .complex(.adType(context.adType), .stats) }
    
    func transform<T: MediationAttemptReport>(
        report: T,
        configuration: AuctionConfiguration
    ) -> MediationAttemptReportCodableModel {
        fatalError("BaseStatisticRequestBuilder can't transform report")
    }
    
    @discardableResult
    func withMediationReport<T: MediationAttemptReport>(
        _ report: T,
        auctionConfiguration: AuctionConfiguration
    ) -> Self {
        self._stats = transform(
            report: report,
            configuration: auctionConfiguration
        )
        return self
    }
    
    @discardableResult
    func withAdTypeContext(_ context: Context) -> Self {
        self.context = context
        return self
    }
    
    required override init() {
        super.init()
    }
}
