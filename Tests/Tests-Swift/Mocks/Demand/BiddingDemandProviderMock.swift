//
//  BiddingDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


final class BiddingContextEncoderMock<Content: Encodable>: BiddingContextEncoder {
    let content: Content

    func encodeBiddingContext(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(content)
    }
    
    init(content: Content) {
        self.content = content
    }
}


final class BiddingDemandProviderMock: DemandProviderMock, BiddingDemandProvider {
    var invokedFetchBiddingContext = false
    var invokedFetchBiddingContextCount = 0
    var stubbedFetchBiddingContext: ((BiddingContextResponse) -> ())?

    func fetchBiddingContext(response: @escaping BiddingContextResponse) {
        invokedFetchBiddingContext = true
        invokedFetchBiddingContextCount += 1
        stubbedFetchBiddingContext?(response)
    }
    
    var invokedPrepareBid = false
    var invokedPrepareBidCount = 0
    var invokedPrepareBidParameters: (payload: String, response: DemandProviderResponse)?
    var invokedPrepareBidParametersList = [(payload: String, response: DemandProviderResponse)]()
    var stubbedPrepareBid: ((String, DemandProviderResponse) -> ())?

    func prepareBid(with payload: String, response: @escaping DemandProviderResponse) {
        invokedPrepareBid = true
        invokedPrepareBidCount += 1
        invokedPrepareBidParameters = (payload, response)
        invokedPrepareBidParametersList.append((payload, response))
        stubbedPrepareBid?(payload, response)
    }
}


extension BiddingDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        var demandId: String!
        var expectedPayload: String?
        
        var biddingContextResult: Result<BiddingContextEncoder, MediationError>?
        var prepareBidResult: Result<DemandAd, MediationError>?
        
        @discardableResult
        func withDemandId(_ identifier: String) -> Self {
            self.demandId = demandId
            return self
        }
        
        @discardableResult
        func withBiddingContextSuccess<Content: Encodable>(_ content: Content) -> Self {
            let encoder = BiddingContextEncoderMock<Content>(content: content)
            self.biddingContextResult = .success(encoder)
            return self
        }
        
        @discardableResult
        func withBiddingContextFailure(_ error: MediationError) -> Self {
            self.biddingContextResult = .failure(error)
            return self
        }
        
        @discardableResult
        func withExpectedPayload(_ payload: String) -> Self {
            self.expectedPayload = payload
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
                    XCTAssertEqual(payload, expectedPayload, "Payloads do")
                }
                
                response(result)
            }
        }
    }
}
