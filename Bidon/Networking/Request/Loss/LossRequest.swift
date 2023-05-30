//
//  LossRequest.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.04.2023.
//

import Foundation


struct LossRequest: Request {
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
        var device: DeviceModel?
        var session: SessionModel?
        var app: AppModel?
        var user: UserModel?
        var regs: RegulationsModel?
        var ext: String?
        var test: Bool
        var token: String?
        var segmentId: String?
        var bid: ImpressionModel
        var externalWinner: ExternalWinner
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var segmentId: String?
        var success: Bool
    }
    
    init<T: LossRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)
    
        self.route = builder.route
        
        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            ext: builder.encodedExt,
            test: builder.testMode,
            bid: builder.imp,
            externalWinner: builder.externalWinner
        )
    }
}
