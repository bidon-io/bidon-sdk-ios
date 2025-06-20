//
//  StatisticRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol StatisticRequestBuilder: AdTypeContextRequestBuilder {
    var stats: EncodableAuctionReportModel { get }
    var route: Route { get }

    @discardableResult
    func withAuctionReport<T: AuctionReport>(_ report: T) -> Self

    init()
}


class BaseStatisticRequestBuilder<Context: AdTypeContext>: BaseRequestBuilder, StatisticRequestBuilder {
    private(set) var context: Context!

    var stats: EncodableAuctionReportModel { _stats }

    private var _stats: EncodableAuctionReportModel!

    var route: Route { .complex(.adType(context.adType), .stats) }

    func transform<T: AuctionReport>(report: T) -> EncodableAuctionReportModel {
        fatalError("BaseStatisticRequestBuilder can't transform report")
    }

    @discardableResult
    func withAuctionReport<T: AuctionReport>(_ report: T) -> Self {
        self._stats = transform(report: report)
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
