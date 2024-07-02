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
    case stats
    case show
    case click
    case reward
    case loss
    case win
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


protocol Request: Equatable {
    associatedtype RequestBody: Encodable & Tokenized
    associatedtype ResponseBody: Decodable & Tokenized
    
    var route: Route { get }
    var method: HTTPTask.HTTPMethod { get }
    var headers: [HTTPTask.HTTPHeader: String] { get }
    var timeout: TimeInterval { get }
    var body: RequestBody? { get }
}


extension Route {
    var stringValue: String {
        switch self {
        case .complex(let left, let right):
            return left.stringValue + "/" + right.stringValue
        default:
            return pathComponent
        }
    }
    
    private var pathComponent: String {
        switch self {
        case .auction:  return "v2/auction"
        case .config:   return "v2/config"
        case .stats:    return "v2/stats"
        case .show:     return "v2/show"
        case .click:    return "v2/click"
        case .loss:     return "v2/loss"
        case .win:      return "v2/win"
        case .reward:   return "v2/reward"
        case .adType(let adType): return adType.stringValue
        default: return ""
        }
    }
    
    func url(_ base: URL) -> URL {
        switch self {
        case .complex(let right, let left):
            return right.url(left.url(base))
        default:
            return base.appendingPathComponent(pathComponent)
        }
    }
}
