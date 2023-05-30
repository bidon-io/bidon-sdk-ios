//
//  File.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct ConfigurationRequest: Request {
    var route: Route = .config
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
    
    struct RequestBody: Encodable, Tokenized {
        var test: Bool
        var token: String?
        var ext: String?
        var segmentId: String?
        var adapters: AdaptersInfo
        var app: AppModel?
        var regs: RegulationsModel?
        var session: SessionModel?
        var user: UserModel?
        var device: DeviceModel?
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var adaptersInitializationParameters: AdaptersInitialisationParameters
        var token: String?
        var segmentId: String?
        
        enum CodingKeys: String, CodingKey {
            case adaptersInitializationParameters = "init"
            case token = "token"
            case segmentId = "segment_id"
        }
    }
    
    init(_ build: (ConfigurationRequestBuilder) -> ()) {
        let builder = ConfigurationRequestBuilder()
        build(builder)
        
        self.body = RequestBody(
            test: builder.testMode,
            ext: builder.encodedExt,
            adapters: builder.adapters,
            app: builder.app,
            regs: builder.regulations,
            session: builder.session,
            user: builder.user,
            device: builder.device
        )
    }
}
