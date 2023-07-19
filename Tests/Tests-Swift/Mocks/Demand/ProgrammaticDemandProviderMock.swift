//
//  ProgrammaticDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


final class ProgrammaticDemandProviderMock: DemandProviderMock, ProgrammaticDemandProvider {
    var invokedBid = false
    var invokedBidCount = 0
    var invokedBidParameters: (pricefloor: Price, response: DemandProviderResponse)?
    var invokedBidParametersList = [(pricefloor: Price, response: DemandProviderResponse)]()
    var stubbedBid: ((Price, DemandProviderResponse) -> ())?
    
    func bid(
        _ pricefloor: Price,
        response: @escaping DemandProviderResponse
    ) {
        invokedBid = true
        invokedBidCount += 1
        invokedBidParameters = (pricefloor, response)
        invokedBidParametersList.append((pricefloor, response))
        stubbedBid?(pricefloor, response)
    }
    
    var invokedFill = false
    var invokedFillCount = 0
    var invokedFillParameters: (ad: DemandAdType, response: DemandProviderResponse)?
    var invokedFillParametersList = [(ad: DemandAdType, response: DemandProviderResponse)]()
    var stubbedFill: ((DemandAdType, DemandProviderResponse) -> ())?
    
    func fill(
        ad: DemandAdType,
        response: @escaping DemandProviderResponse
    ) {
        invokedFill = true
        invokedFillCount += 1
        invokedFillParameters = (ad, response)
        invokedFillParametersList.append((ad, response))
        stubbedFill?(ad, response)
    }
}


extension ProgrammaticDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        var demandId: String!
        var expectedPricefloor: Price?
        var bidResult: Result<DemandAd, MediationError>?
        var fillResult: Result<Void, MediationError>?
        
        @discardableResult
        func withDemandId(_ identifier: String) -> Self {
            self.demandId = demandId
            return self
        }
        
        @discardableResult
        func withExpectedPricefloor(_ expectedPricefloor: Price) -> Self {
            self.expectedPricefloor = expectedPricefloor
            return self
        }
        
        @discardableResult
        func withStubbedBidSuccess(
            id: String = UUID().uuidString,
            eCPM: Double
        ) -> Self {
            let ad = DemandAdMock()
            ad.stubbedId = id
            ad.stubbedNetworkName = self.demandId
            ad.stubbedECPM = eCPM
            
            self.bidResult = .success(ad)
            return self
        }
        
        @discardableResult
        func withStubbedBidFailure(error: MediationError) -> Self {
            self.bidResult = .failure(error)
            return self
        }
        
        @discardableResult
        func withStubbedFillSuccess() -> Self {
            self.fillResult = .success(())
            return self
        }
        
        @discardableResult
        func withStubbedFillFailure(error: MediationError) -> Self {
            self.fillResult = .failure(error)
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        
        self.stubbedBid = { pricefloor, response in
            if let expectedPricefloor = builder.expectedPricefloor {
                XCTAssertEqual(expectedPricefloor, pricefloor, "Received pricefloor doesn't match expected value")
            }
            
            builder.bidResult.map(response)
        }
        
        self.stubbedFill = { ad, response in
            switch builder.bidResult {
            case .success(let _ad):
                XCTAssertIdentical(ad, _ad, "Received ad mock doesn't match an stubbed bid")
            default:
                XCTAssertTrue(false, "Unexpected attempt to fill ad")
            }
            
            switch builder.fillResult {
            case .success:
                response(.success(ad))
            case .failure(let error):
                response(.failure(error))
            default:
                break
            }
        }
    }
}
