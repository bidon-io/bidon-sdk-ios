//
//  DirectDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


final class DirectDemandProviderMock<AdUnitExtras>: DemandProviderMock, DirectDemandProvider
where AdUnitExtras: Decodable & Equatable {
    
    var invokedLoadPricefloorAdUnitExtras = false
    var invokedLoadPricefloorAdUnitExtrasCount = 0
    var invokedLoadPricefloorAdUnitExtrasParameters: (pricefloor: Price, adUnitExtras: AdUnitExtras, response: DemandProviderResponse)?
    var invokedLoadPricefloorAdUnitExtrasParametersList = [(pricefloor: Price, adUnitExtras: AdUnitExtras, response: DemandProviderResponse)]()
    
    var _load: ((Price, AdUnitExtras, @escaping DemandProviderResponse) -> ())?
    
    func load(
        pricefloor: Price,
        adUnitExtras: AdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        invokedLoadPricefloorAdUnitExtras = true
        invokedLoadPricefloorAdUnitExtrasCount += 1
        invokedLoadPricefloorAdUnitExtrasParameters = (pricefloor, adUnitExtras, response)
        invokedLoadPricefloorAdUnitExtrasParametersList.append((pricefloor, adUnitExtras, response))
        
        _load?(pricefloor, adUnitExtras, response)
    }
}


typealias TestDirectDemandProviderMock = DirectDemandProviderMock<TestAdUnitExtras>


extension DirectDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        fileprivate var expectedPricefloor: Double?
        fileprivate var expectedAdUnitExtras: AdUnitExtras?
        fileprivate var result: Result<DemandAd, MediationError>?
        
        @discardableResult
        func withExpectedPricefloor(_ pricefloor: Double) -> Self {
            self.expectedPricefloor = pricefloor
            return self
        }
        
        @discardableResult
        func withExpectedAdUnitExtras(_ extras: AdUnitExtras) -> Self {
            self.expectedAdUnitExtras = extras
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
            
            self.result = .success(ad)
            return self
        }
        
        @discardableResult
        func withStubbedLoadingError(_ error: MediationError) -> Self {
            self.result = .failure(error)
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        
        self._load = { pricefloor, extras, response in
            if let expectedPricefloor = builder.expectedPricefloor {
                XCTAssertEqual(expectedPricefloor, pricefloor, "Recieved pricefloor doesn't match expected value!")
            }
            
            if let expectedExtras = builder.expectedAdUnitExtras {
                XCTAssertEqual(expectedExtras, extras, "Recieved ad unit extras doesn't match expected value!")
            }
            
            if let result = builder.result {
                response(result)
            }
        }
    }
}
