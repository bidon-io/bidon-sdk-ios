//
//  Tests_Swift.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import XCTest

@testable import Bidon


final class TestConcurrentAuctionControllerBuilder: BaseConcurrentAuctionControllerBuilder<AuctionContextMock> {
    override func adapters() -> [AnyDemandSourceAdapter<DemandProviderMock>] {
        let adapters: [AdapterMock] = adaptersRepository.all()
        return adapters.map {
            AnyDemandSourceAdapter(
                adapter: $0,
                provider: $0.stubbedProvider
            )
        }
    }
}


final class ConcurrentAuctionControllerTestCase: XCTestCase {
    typealias AuctionResult = Result<BidModel<DemandProviderMock>, SdkError>
    
    var controller: ConcurrentAuctionController<AuctionContextMock>!
    var contextMock: AuctionContextMock!
    var lineItemElectorMock: AuctionLineItemElectorMock!
    var mediationObserverMock: MediationObserverMock!
    var pricefloor: Price!
    var adaptersRepository: AdaptersRepository!
    var adRevenueObserver: AdRevenueObserver!
    
    override func setUp() {
        contextMock = AuctionContextMock()
        contextMock.stubbedAdType = .interstitial
        
        lineItemElectorMock = AuctionLineItemElectorMock()
        
        mediationObserverMock = MediationObserverMock()
        
        pricefloor = 9.99
        
        adaptersRepository = AdaptersRepository()
        
        adRevenueObserver = BaseAdRevenueObserver()
    }
//    
//    func testAuctionFailureWithEmptyDemand() {
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        var result: AuctionResult!
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [""],
//                bidding: [""]
//            )
//        ]
//        
//        controller = ConcurrentAuctionController { (builder: TestConcurrentAuctionControllerBuilder) in
//            builder.withRounds(rounds)
//            builder.withContext(contextMock)
//            builder.withElector(lineItemElectorMock)
//            builder.withMediationObserver(mediationObserverMock)
//            builder.withPricefloor(pricefloor)
//            builder.withAdaptersRepository(adaptersRepository)
//            builder.withAdRevenueObserver(adRevenueObserver)
//        }
//        
//        controller.load {
//            result = $0
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        switch result {
//        case .success, .none:
//            XCTAssertTrue(false, "Auction result is expected to be failed")
//        case .failure:
//            XCTAssertTrue(true)
//        }
//    }
    
    func testAuctionFailureWithSingleDirectDemand() {
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let lineItem = LineItemModel(
            id: UUID().uuidString,
            pricefloor: pricefloor,
            adUnitId: "some ad unit"
        )
        
        var result: AuctionResult!
        
        let demandAdMock = DemandAdMock()
        demandAdMock.stubbedNetworkName = "test"
        demandAdMock.stubbedId = UUID().uuidString
        demandAdMock.stubbedECPM = pricefloor * 3
        
        let providerMock = DemandProviderMock()
        providerMock.stubbedLoad = { adUnit, response in
            XCTAssertEqual(lineItem.adUnitId, adUnit)
            response(.success(demandAdMock))
        }
        
        let adapterMock = AdapterMock()
        adapterMock.stubbedProvider = providerMock
        adapterMock.stubbedIdentifier = "test"
        adapterMock.stubbedName = "Test Adapter"
        adapterMock.stubbedSdkVersion = "1.0.0"
        adapterMock.stubbedAdapterVersion = "0"
        
        lineItemElectorMock.stubbedPopLineItemResult = lineItem
        adaptersRepository.register(adapter: adapterMock)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: ["test"],
                bidding: [""]
            )
        ]
        
        controller = ConcurrentAuctionController { (builder: TestConcurrentAuctionControllerBuilder) in
            builder.withRounds(rounds)
            builder.withContext(contextMock)
            builder.withElector(lineItemElectorMock)
            builder.withMediationObserver(mediationObserverMock)
            builder.withPricefloor(pricefloor)
            builder.withAdaptersRepository(adaptersRepository)
            builder.withAdRevenueObserver(adRevenueObserver)
        }
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        switch result {
        case .success(let bid):
            XCTAssertIdentical(bid.ad, demandAdMock)
        case .failure, .none:
            XCTAssertTrue(false, "Auction result is expected to be success")
        }
    }
}
