//
//  BiddingDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


struct SomeToken: Encodable, Equatable {
    var token: String = UUID().uuidString
}

struct SomePayload: Decodable, Equatable {
    var payload: String = UUID().uuidString
}


final class ParameterizedBiddingDemandProviderMock<Token: Encodable, Payload: Decodable>: DemandProviderMock, ParameterizedBiddingDemandProvider {
    typealias BiddingContext = Token
    typealias BiddingResponse = Payload
    
    var invokedFetchBiddingContext = false
    var invokedFetchBiddingContextCount = 0
    var stubbedFetchBiddingContext: (((Result<Token, MediationError>) -> ()) -> ())?

    func fetchBiddingContext(response: @escaping (Result<Token, MediationError>) -> ()) {
        invokedFetchBiddingContext = true
        invokedFetchBiddingContextCount += 1
        stubbedFetchBiddingContext?(response)
    }
    
    var invokedPrepareBid = false
    var invokedPrepareBidCount = 0
    var stubbedPrepareBid: ((Payload, DemandProviderResponse) -> ())?

    func prepareBid(
        data: Payload,
        response: @escaping DemandProviderResponse
    ) {
        invokedPrepareBid = true
        invokedPrepareBidCount += 1
        stubbedPrepareBid?(data, response)
    }
}


typealias SomeParameterizedBiddingDemandProviderMock = ParameterizedBiddingDemandProviderMock<SomeToken, SomePayload>

extension SomeParameterizedBiddingDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        var demandId: String!
        var expectedPayload: SomePayload?
        
        var biddingContextResult: Result<SomeToken, MediationError>?
        var prepareBidResult: Result<DemandAd, MediationError>?
        
        @discardableResult
        func withDemandId(_ identifier: String) -> Self {
            self.demandId = demandId
            return self
        }
        
        @discardableResult
        func withBiddingContextSuccess(_ content: String) -> Self {
            let token = SomeToken(token: content)
            self.biddingContextResult = .success(token)
            return self
        }
        
        @discardableResult
        func withBiddingContextFailure(_ error: MediationError) -> Self {
            self.biddingContextResult = .failure(error)
            return self
        }
        
        @discardableResult
        func withExpectedPayload(_ payload: String) -> Self {
            self.expectedPayload = SomePayload(payload: payload)
            return self
        }
        
        @discardableResult
        func withStubbedPrepareSuccess(
            id: String = UUID().uuidString,
            eCPM: Double
        ) -> Self {
            let ad = DemandAdMock()
            ad.stubbedId = id
            ad.stubbedNetworkName = self.demandId
            ad.stubbedECPM = eCPM
            
            self.prepareBidResult = .success(ad)
            return self
        }
        
        @discardableResult
        func withStubbedPrepareFailure(error: MediationError) -> Self {
            self.prepareBidResult = .failure(error)
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        
        if let result = builder.biddingContextResult {
            stubbedFetchBiddingContext = { response in
                response(result)
            }
        }
        
        if let result = builder.prepareBidResult {
            stubbedPrepareBid = { payload, response in
                if let expectedPayload = builder.expectedPayload {
                    XCTAssertEqual(payload, expectedPayload, "Payloads doesn't match")
                }
                
                response(result)
            }
        }
    }
}
