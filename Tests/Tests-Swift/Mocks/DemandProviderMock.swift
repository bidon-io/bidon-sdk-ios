//
//  ProgrammaticDemandProviderMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation
import XCTest

@testable import Bidon


protocol DemandProviderMockBuilder {
    @discardableResult
    func withDemandId(_ identifier: String) -> Self
}


protocol DemandProviderMockBuildable: DemandProviderMock {
    associatedtype Builder: DemandProviderMockBuilder
    
    init(build: (Builder) -> ())
}

                                            
class DemandProviderMock: DemandProvider {
    typealias DemandAdType = DemandAdMock
    
    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: DemandProviderDelegate?
    var invokedDelegateList = [DemandProviderDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: DemandProviderDelegate!

    var delegate: DemandProviderDelegate? {
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
        }
        get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
    }

    var invokedRevenueDelegateSetter = false
    var invokedRevenueDelegateSetterCount = 0
    var invokedRevenueDelegate: DemandProviderRevenueDelegate?
    var invokedRevenueDelegateList = [DemandProviderRevenueDelegate?]()
    var invokedRevenueDelegateGetter = false
    var invokedRevenueDelegateGetterCount = 0
    var stubbedRevenueDelegate: DemandProviderRevenueDelegate!

    var revenueDelegate: DemandProviderRevenueDelegate? {
        set {
            invokedRevenueDelegateSetter = true
            invokedRevenueDelegateSetterCount += 1
            invokedRevenueDelegate = newValue
            invokedRevenueDelegateList.append(newValue)
        }
        get {
            invokedRevenueDelegateGetter = true
            invokedRevenueDelegateGetterCount += 1
            return stubbedRevenueDelegate
        }
    }
    
    var invokedNotify = false
    var invokedNotifyCount = 0
    var invokedNotifyParameters: (ad: DemandAdType, event: AuctionEvent)?
    var invokedNotifyParametersList = [(ad: DemandAdType, event: AuctionEvent)]()
    var stubbedNotify: ((DemandAdType, AuctionEvent) -> ())?

    func notify(ad: DemandAdType, event: AuctionEvent) {
        invokedNotify = true
        invokedNotifyCount += 1
        invokedNotifyParameters = (ad, event)
        invokedNotifyParametersList.append((ad, event))
        stubbedNotify?(ad, event)
    }
}


final class ProgrammaticDemandProviderMock: DemandProviderMock, ProgrammaticDemandProvider {
    var invokedBid = false
    var invokedBidCount = 0
    var invokedBidParameters: (pricefloor: Price, response: DemandProviderResponse)?
    var invokedBidParametersList = [(pricefloor: Price, response: DemandProviderResponse)]()

    func bid(
        _ pricefloor: Price,
        response: @escaping DemandProviderResponse
    ) {
        invokedBid = true
        invokedBidCount += 1
        invokedBidParameters = (pricefloor, response)
        invokedBidParametersList.append((pricefloor, response))
    }

    var invokedFill = false
    var invokedFillCount = 0
    var invokedFillParameters: (ad: DemandAdType, response: DemandProviderResponse)?
    var invokedFillParametersList = [(ad: DemandAdType, response: DemandProviderResponse)]()

    func fill(
        ad: DemandAdType,
        response: @escaping DemandProviderResponse
    ) {
        invokedFill = true
        invokedFillCount += 1
        invokedFillParameters = (ad, response)
        invokedFillParametersList.append((ad, response))
    }
}


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


final class BiddingDemandProviderMock: DemandProviderMock, BiddingDemandProvider {
    var invokedFetchBiddingContext = false
    var invokedFetchBiddingContextCount = 0
    var stubbedFetchBiddingContextResponseResult: (Result<BiddingContextEncoder, MediationError>, Void)?

    func fetchBiddingContext(response: @escaping BiddingContextResponse) {
        invokedFetchBiddingContext = true
        invokedFetchBiddingContextCount += 1
        if let result = stubbedFetchBiddingContextResponseResult {
            response(result.0)
        }
    }

    var invokedPrepareBid = false
    var invokedPrepareBidCount = 0
    var invokedPrepareBidParameters: (payload: String, response: DemandProviderResponse)?
    var invokedPrepareBidParametersList = [(payload: String, response: DemandProviderResponse)]()

    func prepareBid(with payload: String, response: @escaping DemandProviderResponse) {
        invokedPrepareBid = true
        invokedPrepareBidCount += 1
        invokedPrepareBidParameters = (payload, response)
        invokedPrepareBidParametersList.append((payload, response))
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
