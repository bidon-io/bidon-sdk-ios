//
//  AuctionRequest.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AuctionRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
    
    struct RequestBody: Encodable, Tokenized {
        struct AdObjectModel: Encodable {
            var orientation: InterfaceOrientation = .current
            var auctionId: String
            var pricefloor: Price
            var banner: BannerAdTypeContextModel?
            var interstitial: InterstitialAdTypeContextModel?
            var rewarded: RewardedAdTypeContextModel?
        }
        
        var device: DeviceModel
        var session: SessionModel
        var app: AppModel
        var user: UserModel
        var regs: RegulationsModel
        var segment: SegmentModel
        var ext: String?
        var test: Bool
        var token: String?
        var adObject: AdObjectModel
        var adapters: AdaptersInfo
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var rounds: [AuctionRoundModel]
        var lineItems: [LineItemModel]
        var pricefloor: Price
        var token: String?
        var auctionId: String
        var segment: SegmentResponseModel?
        var auctionConfigurationId: Int
        var auctionConfigurationUid: String
        var externalWinNotifications: Bool
    }
}


extension AuctionRequest {
    init<T: AuctionRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)
        
        self.route = .complex(.adType(builder.adType), .auction)
        
        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            segment: builder.segment,
            ext: builder.encodedExt,
            test: builder.testMode,
            adObject: builder.adObject,
            adapters: builder.adapters
        )
    }
}


extension AuctionRequest: Equatable {
    static func == (lhs: AuctionRequest, rhs: AuctionRequest) -> Bool {
        return lhs.body?.adObject.auctionId == rhs.body?.adObject.auctionId
    }    
}
