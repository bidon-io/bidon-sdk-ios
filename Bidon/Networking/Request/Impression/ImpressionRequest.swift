//
//  ActionRequest.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct ImpressionRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
    
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
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var segmentId: String?
        var success: Bool
    }
    
    init<T: ImpressionRequestBuilder>(_ build: (T) -> ()) {
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
            bid: builder.imp
        )
    }
}
