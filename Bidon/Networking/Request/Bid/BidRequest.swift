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
        struct BidModel: Decodable, PendingBid {
            enum CodingKeys: String, CodingKey {
                case id
                case impressionId = "impid"
                case winNoticeUrl = "nurl"
                case billingNoticeUrl = "burl"
                case lossNoticeUrl = "lurl"
                case payload = "ext"
                case adUnit = "ad_unit"
                case price
            }
            
            var id: String
            var impressionId: String
            var winNoticeUrl: String?
            var billingNoticeUrl: String?
            var lossNoticeUrl: String?
            var adUnit: AdUnitModel
            var price: Price
            var payload: Decoder
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .id)
                impressionId = try container.decode(String.self, forKey: .impressionId)
                winNoticeUrl = try container.decodeIfPresent(String.self, forKey: .winNoticeUrl)
                lossNoticeUrl = try container.decodeIfPresent(String.self, forKey: .lossNoticeUrl)
                adUnit = try container.decode(AdUnitModel.self, forKey: .adUnit)
                price = try container.decode(Price.self, forKey: .price)
                payload = try container.superDecoder(forKey: .payload)
            }
            
            static func == (
                lhs: BidRequest.ResponseBody.BidModel,
                rhs: BidRequest.ResponseBody.BidModel
            ) -> Bool {
                return lhs.id == rhs.id
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }            
        }
        
        var token: String?
        var bids: [BidModel]
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
