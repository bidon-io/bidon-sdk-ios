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
        var device: DeviceModel
        var session: SessionModel
        var app: AppModel
        var user: UserModel
        var regs: RegulationsModel
        var segment: SegmentModel
        var ext: String?
        var test: Bool
        var token: String?
        var stats: MediationAttemptReportCodableModel
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var success: Bool
    }
}


extension StatisticRequest {
    init(_ build: (StatisticRequestBuilder) -> ()) {
        let builder = StatisticRequestBuilder()
        build(builder)
        
        self.route = .complex(.adType(builder.adType), .stats)
        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            segment: builder.segment,
            ext: builder.encodedExt,
            test: builder.testMode,
            stats: builder.stats
        )
    }
}


extension StatisticRequest: Equatable {
    static func == (lhs: StatisticRequest, rhs: StatisticRequest) -> Bool {
        return lhs.body?.stats.auctionId == rhs.body?.stats.auctionId
    }
}
