//
//  StatisticRequest.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct StatisticRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?

    struct RequestBody: Encodable, Tokenized {
        let stats: EncodableAuctionReportModel
        let device: DeviceModel
        let session: SessionModel
        let app: AppModel
        let user: UserModel
        let regs: RegulationsModel
        var ext: String?
        let segment: SegmentModel
        var token: String?
    }

    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var success: Bool
    }
}


extension StatisticRequest {
    init<T: StatisticRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)

        self.route = builder.route
        self.body = RequestBody(
            stats: builder.stats,
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            ext: builder.encodedExt,
            segment: builder.segment
        )
    }
}


extension StatisticRequest: Equatable {
    static func == (lhs: StatisticRequest, rhs: StatisticRequest) -> Bool {
        return lhs.body?.stats.configuration.auctionId == rhs.body?.stats.configuration.auctionId
    }
}

extension AuctionRoundReportModel {

    func adUnits(winner: AnyAdUnit?) -> [EncodableAuctionReportModel.EncodableAuctionAdUnit] {
        let allDemands = self.demands + (self.bidding?.demands ?? [])
        return allDemands.map { demand in
            return EncodableAuctionReportModel.EncodableAuctionAdUnit(
                price: demand.bid?.price ?? demand.adUnit?.pricefloor,
                tokenStart: demand.tokenStartTimestamp,
                tokenFinish: demand.tokenFinishTimestamp,
                fillStart: demand.startTimestamp,
                fillFinish: demand.finishTimestamp,
                demandId: demand.demandId,
                bidType: demand.adUnit?.bidType ?? .direct,
                adUnitUid: demand.adUnit?.uid ?? "",
                adUnitLabel: demand.adUnit?.label ?? "",
                status: demand.status
            )
        }
    }
}
