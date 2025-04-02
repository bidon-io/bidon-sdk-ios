//
//  HTTPClient.swift
//  Bidon
//
//  Created by Bidon Team on 04.08.2022.
//

import Foundation


struct HTTPTask {
    typealias HTTPHeaders = [HTTPHeader: String]
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum HTTPError: Error {
        case unsupportedURL
        case invalidResponse
        case rateLimitted(retryAfterSeconds: TimeInterval)
        case encoding(Error)
        case decoding(Error)
        case networking(Error)
    }
    
    enum HTTPHeader {
        case contentType
        case accept
        case sdkVersion
        case retryAfter
        case custom(String)
    }
    
    let baseURL: String
    let route: Route
    let body: Data?
    let method: HTTPMethod
    let timeout: TimeInterval
    let headers: HTTPHeaders
    let completion: (Result<Data, HTTPError>) -> ()
    
    func resume() {
        guard let url = URL(string: baseURL).map({ route.url($0) }) else {
            completion(.failure(.unsupportedURL))
            return
        }
        
        let session = URLSession.shared
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout
        )
        
        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header.stringValue)
        }
        
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            if response.statusCode >= 200, response.statusCode < 300, let data = data {
                completion(.success(data))
            } else if let retryAfter = response.retryAfterSeconds, retryAfter > 0 {
                completion(.failure(.rateLimitted(retryAfterSeconds: retryAfter)))
            } else if let error = error {
                completion(.failure(.networking(error)))
            } else {
                completion(.failure(.invalidResponse))
            }
        }
    
        task.resume()
    }
}


private extension HTTPURLResponse {
    var retryAfterSeconds: TimeInterval? {
        return allHeaderFields[HTTPTask.HTTPHeader.retryAfter.stringValue]
            .flatMap { $0 as? String }
            .flatMap { Double($0) }
            .map { Date.MeasurementUnits.milliseconds.convert($0, to: .seconds) }
    }
}


extension HTTPTask.HTTPHeader: Hashable {
    var stringValue: String {
        switch self {
        case .contentType: return "Content-Type"
        case .accept: return "Accept"
        case .sdkVersion: return "X-Bidon-Version"
        case .retryAfter: return "Retry-After"
        case .custom(let header): return header
        }
    }
    
    init(stringValue: String) {
        self = .custom(stringValue)
    }
}
