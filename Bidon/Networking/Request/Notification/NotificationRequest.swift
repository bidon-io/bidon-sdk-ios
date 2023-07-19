//
//  NotificationRequest.swift
//  Bidon
//
//  Created by Bidon Team on 05.04.2023.
//

import Foundation


struct NotificationRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
    
    struct ExternalWinner: Encodable {
        var ecpm: Price
        var demandId: String
    }
    
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
        var bid: ImpressionModel
        var externalWinner: ExternalWinner?
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var success: Bool
    }
}


extension NotificationRequest {
    init<T: NotificationRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)
        
        self.route = builder.route
        
        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            segment: builder.segment,
            ext: builder.encodedExt,
            test: builder.testMode,
            bid: builder.imp,
            externalWinner: builder.externalWinner
        )
    }
}


extension NotificationRequest: Equatable {
    static func == (lhs: NotificationRequest, rhs: NotificationRequest) -> Bool {
        return lhs.body?.bid.impressionId == rhs.body?.bid.impressionId &&
        lhs.route.stringValue == rhs.route.stringValue
    }
}
