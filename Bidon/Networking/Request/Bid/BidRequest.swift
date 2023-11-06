//
//  BidRequest.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


struct BidRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
   
    struct RequestBody: Encodable, Tokenized {
        struct ImpModel: Encodable {
            var id: String = UUID().uuidString
            var bidfloor: Price
            var auctionId: String
            var auctionConfigurationUid: String
            var roundId: String
            var orientation: InterfaceOrientation = .current
            var banner: BannerAdTypeContextModel?
            var interstitial: InterstitialAdTypeContextModel?
            var rewarded: RewardedAdTypeContextModel?
            var demands: EncodableBiddingDemandTokens
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
        var adapters: AdaptersInfo
        var imp: ImpModel
    }
    
    struct ResponseBody: Decodable, Tokenized {
        var token: String?
        var bids: [ServerBidModel]
    }
}


extension BidRequest {
    init<T: BidRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)
        
        self.route = .complex(.adType(builder.adType), .bid)
        
        self.body = RequestBody(
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            segment: builder.segment,
            ext: builder.encodedExt,
            test: builder.testMode,
            adapters: builder.adapters,
            imp: builder.imp
        )
    }
}


extension BidRequest: Equatable {
    static func == (lhs: BidRequest, rhs: BidRequest) -> Bool {
        return lhs.body?.imp.id == rhs.body?.imp.id
    }
}
