//
//  File.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct ConfigurationRequest: Request {
    var id: String = UUID().uuidString
    var route: Route = .config
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?

    struct RequestBody: Encodable, Tokenized {
        let device: DeviceModel
        let session: SessionModel
        let app: AppModel
        let user: UserModel
        let regs: RegulationsModel
        let adapters: AdaptersInfo
        var ext: String?
        var token: String?
        let test: Bool
    }

    struct ResponseBody: Decodable, Tokenized {
        struct Bidding: Decodable {
            var tokenTimeoutMs: TimeInterval
        }
        let adaptersInitializationParameters: AdaptersInitialisationParameters
        let placements: [PlacementModel]
        let segment: SegmentResponseModel?
        var token: String?
        let bidding: Bidding

        enum CodingKeys: String, CodingKey {
            case adaptersInitializationParameters = "init"
            case token = "token"
            case segment
            case placements
            case bidding
        }
    }
}


extension ConfigurationRequest {
    init(_ build: (ConfigurationRequestBuilder) -> ()) {
        let builder = ConfigurationRequestBuilder()
        build(builder)

        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            adapters: builder.adapters,
            ext: builder.encodedExt,
            test: builder.testMode
        )
    }
}


extension ConfigurationRequest: Equatable {
    static func == (lhs: ConfigurationRequest, rhs: ConfigurationRequest) -> Bool {
        return lhs.id == rhs.id
    }
}
