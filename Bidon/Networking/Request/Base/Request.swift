//
//  Request.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


indirect enum Route {
    case config
    case auction
    case bid
    case stats
    case show
    case click
    case reward
    case loss
    case adType(AdType)
    case complex(Route, Route)
}


extension HTTPTask.HTTPHeaders {
    static func `default`() -> HTTPTask.HTTPHeaders {
        return [
            .contentType : "application/json",
            .accept: "application/json",
            .sdkVersion: BidonSdk.sdkVersion
        ]
    }
}


protocol Tokenized {
    var token: String? { get set }
}


protocol Request {
    associatedtype RequestBody: Encodable & Tokenized
    associatedtype ResponseBody: Decodable & Tokenized
    
    var route: Route { get }
    var method: HTTPTask.HTTPMethod { get }
    var headers: [HTTPTask.HTTPHeader: String] { get }
    var timeout: TimeInterval { get }
    var body: RequestBody? { get }
}


extension Route {
    func url(_ base: URL) -> URL {
        switch self {
        case .auction: return base.appendingPathComponent("auction")
        case .config: return base.appendingPathComponent("config")
        case .stats: return base.appendingPathComponent("stats")
        case .bid: return base.appendingPathComponent("bidding")
        case .show: return base.appendingPathComponent("show")
        case .click: return base.appendingPathComponent("click")
        case .loss: return base.appendingPathComponent("loss")
        case .reward: return base.appendingPathComponent("reward")
        case .adType(let adType): return base.appendingPathComponent(adType.stringValue)
        case .complex(let right, let left): return right.url(left.url(base))
        }
    }
}
