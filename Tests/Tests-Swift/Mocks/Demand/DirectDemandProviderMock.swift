//
//  DirectDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


final class DirectDemandProviderMock: DemandProviderMock, DirectDemandProvider {
    var invokedLoad = false
    var invokedLoadCount = 0
    var invokedLoadParameters: (adUnitId: String, response: DemandProviderResponse)?
    var invokedLoadParametersList = [(adUnitId: String, response: DemandProviderResponse)]()
    var stubbedLoad: ((String, @escaping DemandProviderResponse) -> ())?
    
    func load(
        _ adUnitId: String,
        response: @escaping DemandProviderResponse
    ) {
        invokedLoad = true
        invokedLoadCount += 1
        invokedLoadParameters = (adUnitId, response)
        invokedLoadParametersList.append((adUnitId, response))
        stubbedLoad?(adUnitId, response)
    }
}


extension DirectDemandProviderMock: DemandProviderMockBuildable {
    final class Builder: DemandProviderMockBuilder {
        var demandId: String!
        var expectedLineItem: LineItem?
        var result: Result<DemandAd, MediationError>?
        
        @discardableResult
        func withDemandId(_ identifier: String) -> Self {
            self.demandId = demandId
            return self
        }
        
        @discardableResult
        func withExpectedLineItem(_ expectedLineItem: LineItem) -> Self {
            self.expectedLineItem = expectedLineItem
            return self
        }
        
        @discardableResult
        func withStubbedLoadSuccess(
            id: String = UUID().uuidString,
            eCPM: Double
        ) -> Self {
            let ad = DemandAdMock()
            ad.stubbedId = id
            ad.stubbedNetworkName = self.demandId
            ad.stubbedECPM = eCPM
            
            self.result = .success(ad)
            return self
        }
        
        @discardableResult
        func withStubbedLoadFailure(error: MediationError) -> Self {
            self.result = .failure(error)
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        self.stubbedLoad = { adUnitId, response in
            if let lineItem = builder.expectedLineItem {
                XCTAssertEqual(adUnitId, lineItem.adUnitId, "Recieved ad unit doesn't match expected value!")
            }
            
            if let result = builder.result {
                response(result)
            }
        }
    }
}
