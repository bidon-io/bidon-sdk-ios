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
            let auctionId: String
            let auctionKey: String?
            let pricefloor: Price
            let orientation: InterfaceOrientation = .current
            var banner: BannerAdTypeContextModel?
            var interstitial: InterstitialAdTypeContextModel?
            var rewarded: RewardedAdTypeContextModel?
            let demands: EncodableBiddingDemandTokens
            
            enum CodingKeys: String, CodingKey {
                case auctionId = "auction_id"
                case auctionKey = "auction_key"
                case pricefloor = "auction_pricefloor"
                case orientation
                case banner
                case interstitial
                case rewarded
                case demands
            }
        }
        
        let device: DeviceModel
        let session: SessionModel
        let app: AppModel
        let user: UserModel
        let regs: RegulationsModel
        let adapters: AdaptersInfo
        let ext: String?
        let segment: SegmentModel
        let adObject: AdObjectModel
        var token: String?
        let test: Bool
    }
    
    struct ResponseBody: Decodable, Tokenized {
        let adUnits: [AdUnitModel]
        let noBids: [AdUnitModel]?
        let segment: SegmentResponseModel?
        var token: String?
        let auctionId: String
        let auctionConfigurationId: Int
        let auctionConfigurationUid: String
        let pricefloor: Price
        let auctionTimeout: Float
        var externalWinNotifications: Bool
        
        enum CodingKeys: String, CodingKey {
            case adUnits
            case segment
            case token
            case auctionId
            case auctionConfigurationId
            case auctionConfigurationUid
            case auctionPricefloor
            case auctionTimeout
            case noBids
            case externalWinNotifications
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            adUnits = try container.decode([AdUnitModel].self, forKey: .adUnits)
            segment = try container.decodeIfPresent(SegmentResponseModel.self, forKey: .segment)
            token = try container.decodeIfPresent(String.self, forKey: .token)
            auctionId = try container.decode(String.self, forKey: .auctionId)
            auctionConfigurationId = try container.decode(Int.self, forKey: .auctionConfigurationId)
            auctionConfigurationUid = try container.decode(String.self, forKey: .auctionConfigurationUid)
            pricefloor = try container.decode(Price.self, forKey: .auctionPricefloor)
            auctionTimeout = try container.decodeIfPresent(Float.self, forKey: .auctionTimeout) ?? Constants.Timeout.defaultAuctionTimeout
            noBids = try container.decodeIfPresent([AdUnitModel].self, forKey: .noBids)
            externalWinNotifications = try container.decode(Bool.self, forKey: .externalWinNotifications)
        }
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
            adapters: builder.adapters, 
            ext: builder.encodedExt,
            segment: builder.segment,
            adObject: builder.adObject,
            test: builder.testMode
        )
    }
}


extension AuctionRequest: Equatable {
    static func == (lhs: AuctionRequest, rhs: AuctionRequest) -> Bool {
        return lhs.body?.adObject.auctionId == rhs.body?.adObject.auctionId
    }    
}
