//
//  NetworkManagerMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


final class NetworkManagerMockProxy: NetworkManager {
    var baseURL: String = ""
    
    private var mocks: [NetworkManager] = []
    
    func perform<T>(
        request: T,
        completion: @escaping Completion<T>
    ) where T : Request {
        guard let mock = mocks.compactMap({ $0 as? NetworkManagerMock<T> }).first else {
            XCTAssertTrue(false, "NetworkManagerMock for request \(request) is stubbed" )
            return
        }
        
        mock.perform(
            request: request,
            completion: completion
        )
    }
    
    func stub<T: Request>(
        _ request: T,
        result: Result<T.ResponseBody, HTTPTask.HTTPError>
    ) {
        let mock = NetworkManagerMock<T>()
        mock.stubbedPerform = { _request, completion in
            XCTAssertEqual(request, _request, "Recieved request doesn't match expected")
            completion(result)
        }
        
        mocks.append(mock)
    }
}


final class NetworkManagerMock<RequestType: Request>: NetworkManager {
    var invokedBaseURLSetter = false
    var invokedBaseURLSetterCount = 0
    var invokedBaseURL: String?
    var invokedBaseURLList = [String]()
    var invokedBaseURLGetter = false
    var invokedBaseURLGetterCount = 0
    var stubbedBaseURL: String! = ""
        
    var baseURL: String {
        set {
            invokedBaseURLSetter = true
            invokedBaseURLSetterCount += 1
            invokedBaseURL = newValue
            invokedBaseURLList.append(newValue)
        }
        get {
            invokedBaseURLGetter = true
            invokedBaseURLGetterCount += 1
            return stubbedBaseURL
        }
    }

    var invokedPerform = false
    var invokedPerformCount = 0
    var stubbedPerform: ((RequestType, Completion<RequestType>) -> ())?

    func perform<T: Request>(
        request: T,
        completion: @escaping Completion<T>
    ) {
        invokedPerform = true
        invokedPerformCount += 1
        guard
            let request = request as? RequestType,
            let completion = completion as? Completion<RequestType>
        else {
            XCTAssertTrue(false, "NetworkManagerMock received request has invalid type")
            return
        }
        
        stubbedPerform?(request, completion)
    }
}
