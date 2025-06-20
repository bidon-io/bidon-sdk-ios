//
//  ConcurrentAuctionControllerTestCase+CornerCases.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 07.12.2023.
//

import Foundation


import Foundation
import XCTest

@testable import Bidon


//extension ConcurrentAuctionControllerTestCase {
//    func testShouldProperlyHandleEarlyCancel() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 5
//        
//        let demandId1 = "demand_id_1"
//        
//        let price1 = pricefloor * 3
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedPricefloor(self.pricefloor)
//            builder.withExpectedAdUnitExtras(adUnit1.extras)
//            builder.withStubbedDemandAd(price: price1)
//        }
//        
//        adaptersRepository.register(adapter: adapterMock1)
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [demandId1],
//                bidding: [""]
//            ),
//        ]
//        
//        let adUnits: [AdUnitModel] = [
//            adUnit1
//        ].map { $0.adUnit }
//        
//        controller = controller(
//            rounds: rounds,
//            adUnits: adUnits
//        )
//        
//        controller.load {
//            result = $0
//            expectation.fulfill()
//        }
//        controller.cancel()
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        let provider = (adapterMock1.stubbedProvider as! TestDirectDemandProviderMock)
//        XCTAssertEqual(provider.invokedLoadPricefloorAdUnitExtrasCount, 0)
//        
//        XCTAssertEqual(report.result.status, .cancelled)
//        XCTAssertNil(report.result.winner)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//    }
//}
