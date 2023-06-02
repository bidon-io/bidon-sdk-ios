//
//  BidRequest.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


struct BidRequest: Request {
    var route: Route
    var method: HTTPTask.HTTPMethod = .post
    var headers: [HTTPTask.HTTPHeader: String] = .default()
    var timeout: TimeInterval = 10
    var body: RequestBody?
    
    struct ExtrasModel: Codable {
        var bidon: BidonBiddingExtrasModel
    }
    
    struct RequestBody: Encodable, Tokenized {
        struct ImpModel: Encodable {
            var bidfloor: Price
            var id: String = UUID().uuidString
            var auctionId: String
            var auctionConfigurationId: Int
            var roundId: String
            var orientation: InterfaceOrientation = .current
            var banner: AdViewAucionContextModel?
            var ext: ExtrasModel
        }
        
        var id: String
        var device: DeviceModel?
        var session: SessionModel?
        var app: AppModel?
        var user: UserModel?
        var regs: RegulationsModel?
        var ext: String?
        var test: Bool
        var token: String?
        var segmentId: String?
        var imp: [ImpModel]
    }
    
    struct ResponseBody: Decodable, Tokenized {
        enum Status: Int, Decodable {
            case ok = 0
        }
        
        struct Bid: Decodable {
            enum CodingKeys: String, CodingKey {
                case id
                case impressionId = "impid"
                case winNoticeUrl = "nurl"
                case billingNoticeUrl = "burl"
                case lossNoticeUrl = "lurl"
                case price
                case ext
            }
            
            var id: String
            var impressionId: String
            var winNoticeUrl: String?
            var billingNoticeUrl: String?
            var lossNoticeUrl: String?
            var price: Price
            var ext: BidonBiddingExtrasModel
        }
        
        struct SeatBid: Decodable {
            var demandId: String
            var bids: [Bid]
            
            enum CodingKeys: String, CodingKey {
                case demandId = "seat"
                case bids = "bid"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case seatBids = "seatbid"
            case bidId = "bidid"
            case status = "nbr"
        }
        
        var token: String?
        var segmentId: String?
        var id: String
        var seatBids: [SeatBid]?
        var bidId: String?
        var status: Status
    }
    
    init<T: BidRequestBuilder>(_ build: (T) -> ()) {
        let builder = T()
        build(builder)
        
        self.route = .complex(.adType(builder.adType), .bid)
        
        self.body = RequestBody(
            id: UUID().uuidString,
            device: builder.device,
            session: builder.session,
            app: builder.app,
            user: builder.user,
            regs: builder.regulations,
            ext: builder.encodedExt,
            test: builder.testMode,
            imp: [builder.imp]
        )
    }
}


