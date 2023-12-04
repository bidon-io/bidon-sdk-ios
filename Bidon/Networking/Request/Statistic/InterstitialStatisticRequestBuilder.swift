//
//  InterstitialStatisticRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.11.2023.
//

import Foundation


final class InterstitialStatisticRequestBuilder: BaseStatisticRequestBuilder<InterstitialAdTypeContext> {
    override func transform<T>(report: T) -> EncodableAuctionReportModel where T : AuctionReport {
        return EncodableAuctionReportModel(
            report: report,
            interstitial: InterstitialAdTypeContextModel(context)
        )
    }
}
