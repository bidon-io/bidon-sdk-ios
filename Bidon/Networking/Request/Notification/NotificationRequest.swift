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
        let price: Price
        let demandId: String
    }
    
    struct RequestBody: Encodable, Tokenized {
        let device: DeviceModel
        let session: SessionModel
        let app: AppModel
        let user: UserModel
        let regs: RegulationsModel
        let segment: SegmentModel
        let ext: String?
        let test: Bool
        var token: String?
        let bid: ImpressionModel
        let externalWinner: ExternalWinner?
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        let success: Bool
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
        return lhs.body?.bid.adUnitUid == rhs.body?.bid.adUnitUid &&
        lhs.body?.bid.adUnitLabel == rhs.body?.bid.adUnitLabel &&
        lhs.route.stringValue == rhs.route.stringValue
    }
}
