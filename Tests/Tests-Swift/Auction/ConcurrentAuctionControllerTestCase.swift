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
    var mediationObserver: BaseMediationObserver!
    
    var auctionId: String!
    var auctionConfigurationId: Int!
    var adType: AdType!
    
    var contextMock: AuctionContextMock!
    var lineItemElectorMock: AuctionLineItemElectorMock!
    var pricefloor: Price!
    var adaptersRepository: AdaptersRepository!
    var adRevenueObserver: AdRevenueObserver!
    
    override func setUp() {
        adType = .interstitial
        auctionId = UUID().uuidString
        auctionConfigurationId = Int.random(in: 0..<Int.max)
        pricefloor = Double.random(in: 9.99...999.99)
        
        contextMock = AuctionContextMock()
        contextMock.stubbedAdType = adType
        
        lineItemElectorMock = AuctionLineItemElectorMock()
        
        adaptersRepository = AdaptersRepository()
        adRevenueObserver = BaseAdRevenueObserver()
        mediationObserver = BaseMediationObserver(
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            adType: .interstitial
        )
    }
    
    final func controller(with rounds: [AuctionRoundMock]) -> ConcurrentAuctionController<AuctionContextMock> {
        return ConcurrentAuctionController { (builder: TestConcurrentAuctionControllerBuilder) in
            builder.withRounds(rounds)
            builder.withContext(contextMock)
            builder.withElector(lineItemElectorMock)
            builder.withMediationObserver(mediationObserver)
            builder.withPricefloor(pricefloor)
            builder.withAdaptersRepository(adaptersRepository)
            builder.withAdRevenueObserver(adRevenueObserver)
        }
    }
    
    func testAuctionFailureWithEmptyDemand() {
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        var result: AuctionResult!
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [""],
                bidding: [""]
            )
        ]
        
        controller = controller(with: rounds)
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        switch result {
        case .success, .none:
            XCTAssertTrue(false, "Auction result is expected to be failed")
        case .failure:
            XCTAssertTrue(true)
        }
        
        let report = mediationObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertEqual(report.auctionId, auctionId)
        XCTAssertEqual(report.auctionConfigurationId, auctionConfigurationId)
        XCTAssertEqual(report.auctionId, auctionId)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, "round_1")
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, "")
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "UNKNOWN_ADAPTER")
    }
}
