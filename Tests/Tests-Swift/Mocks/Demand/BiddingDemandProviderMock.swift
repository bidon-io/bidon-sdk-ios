//
//  BiddingDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


struct SomePayload: Decodable, Equatable {
    var payload: String = UUID().uuidString
}


final class BiddingDemandProviderMock<AdUnitExtras, BiddingToken, BiddingPayload>: DemandProviderMock, BiddingDemandProvider
where AdUnitExtras: Decodable & Equatable, BiddingToken: Encodable & Equatable, BiddingPayload: Decodable & Equatable {
    
    var invokedCollectBiddingToken = false
    var invokedCollectBiddingTokenCount = 0
    var invokedCollectBiddingTokenParameters: (adUnitExtras: [AdUnitExtras], Void)?
    var invokedCollectBiddingTokenParametersList = [(adUnitExtras: [AdUnitExtras], Void)]()
    var stubbedCollectBiddingTokenResponseResult: (Result<BiddingToken, MediationError>, Void)?
    
    var _collectBiddingToken: (([AdUnitExtras], @escaping (Result<BiddingToken, MediationError>) -> ()) -> ())?
    
    func collectBiddingToken(
        biddingTokenExtras: [AdUnitExtras],
        response: @escaping (Result<BiddingToken, MediationError>) -> ()
    ) {
        invokedCollectBiddingToken = true
        invokedCollectBiddingTokenCount += 1
        invokedCollectBiddingTokenParameters = (adUnitExtras, ())
        invokedCollectBiddingTokenParametersList.append((adUnitExtras, ()))
        
        _collectBiddingToken?(adUnitExtras, response)
    }

    var invokedLoadPayload = false
    var invokedLoadPayloadCount = 0
    var invokedLoadPayloadParameters: (payload: BiddingPayload, adUnitExtras: AdUnitExtras?, response: DemandProviderResponse)?
    var invokedLoadPayloadParametersList = [(payload: BiddingPayload, adUnitExtras: AdUnitExtras?, response: DemandProviderResponse)]()

    var _load: ((BiddingPayload, AdUnitExtras, @escaping DemandProviderResponse) -> ())?
    
    func load(
        payload: BiddingPayload,
        adUnitExtras: AdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        invokedLoadPayload = true
        invokedLoadPayloadCount += 1
        invokedLoadPayloadParameters = (payload, adUnitExtras, response)
        invokedLoadPayloadParametersList.append((payload, adUnitExtras, response))
        
        _load?(payload, adUnitExtras, response)
    }
}


typealias TestBiddingDemandProviderMock = BiddingDemandProviderMock<TestAdUnitExtras, TestBiddingToken, TestBiddingPayload>


extension BiddingDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        fileprivate var expectedBiddingPayload: BiddingPayload?
        fileprivate var expectedAdUnitExtras: AdUnitExtras?
        fileprivate var expectedAdUnitTokenExtras: [AdUnitExtras]?

        var biddingContextResult: Result<BiddingToken, MediationError>?
        var prepareBidResult: Result<DemandAd, MediationError>?
        
        @discardableResult
        func withExpectedAdUnitTokenExtras(_ extras: [AdUnitExtras]) -> Self {
            self.expectedAdUnitTokenExtras = extras
            return self
        }
        
        @discardableResult
        func withExpectedAdUnitExtras(_ extras: AdUnitExtras) -> Self {
            self.expectedAdUnitExtras = extras
            return self
        }
        
        @discardableResult
        func withBiddingToken(_ token: BiddingToken) -> Self {
            self.biddingContextResult = .success(token)
            return self
        }
        
        @discardableResult
        func withBiddingTokenError(_ error: MediationError) -> Self {
            self.biddingContextResult = .failure(error)
            return self
        }
        
        @discardableResult
        func withExpectedPayload(_ payload: BiddingPayload) -> Self {
            self.expectedBiddingPayload = payload
            return self
        }
        
        @discardableResult
        func withStubbedDemandAd(
            id: String = UUID().uuidString,
            price: Double
        ) -> Self {
            let ad = DemandAdMock()
            ad.stubbedId = id
            ad.stubbedPrice = price
            
            self.prepareBidResult = .success(ad)
            return self
        }
        
        @discardableResult
        func withStubbedLoadingError(_ error: MediationError) -> Self {
            self.prepareBidResult = .failure(error)
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        
        if let result = builder.biddingContextResult {
            _collectBiddingToken = { extras, response in
                if let expectedAdUnitTokenExtras = builder.expectedAdUnitTokenExtras {
                    XCTAssertEqual(extras, expectedAdUnitTokenExtras, "Recieved ad unit extras doesn't match expected value!")
                }
                response(result)
            }
        }
        
        if let result = builder.prepareBidResult {
            _load = { payload, extras, response in
                if let expectedExtras = builder.expectedAdUnitExtras {
                    XCTAssertEqual(extras, expectedExtras, "Recieved ad unit extras doesn't match expected value!")
                }
                
                if let expectedPayload = builder.expectedBiddingPayload {
                    XCTAssertEqual(payload, expectedPayload, "Payloads doesn't match")
                }
                
                response(result)
            }
        }
    }
}
