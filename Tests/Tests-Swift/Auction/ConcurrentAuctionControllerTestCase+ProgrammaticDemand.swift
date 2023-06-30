//
//  ConcurrentAuctionControllerTestCase+ProgrammaticDemand.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 30.06.2023.
//

import Foundation
import XCTest

@testable import Bidon


extension ConcurrentAuctionControllerTestCase {
    func testAuctionSuccessWithSingleProgrammaticDemand() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let eCPM1 = pricefloor * 1.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidSuccess(eCPM: eCPM1)
            builder.withStubbedFillSuccess()
        }

        adaptersRepository.register(adapter: adapterMock1)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1],
                bidding: [""]
            )
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: []
        )

        controller.load {
            result = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")

        let report = mediationObserver.report

        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerECPM, eCPM1)
        XCTAssertEqual(report.result.winnerNetworkId, demandId1)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionSuccessWithMultipleBidsProgrammaticDemand() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let demandId2 = "demand_id_2"
        
        let eCPM1 = pricefloor * 1.5
        let eCPM2 = pricefloor * 2.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidSuccess(eCPM: eCPM1)
            builder.withStubbedFillSuccess()
        }
        
        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(eCPM1)
            builder.withStubbedBidSuccess(eCPM: eCPM2)
            builder.withStubbedFillSuccess()
        }

        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)

        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1],
                bidding: [""]
            ),
            AuctionRoundMock(
                id: "round_2",
                timeout: timeout,
                demands: [demandId2],
                bidding: [""]
            )
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: []
        )

        controller.load {
            result = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")

        let report = mediationObserver.report

        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerECPM, eCPM2)
        XCTAssertEqual(report.result.winnerNetworkId, demandId2)

        XCTAssertEqual(report.rounds.count, 2)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "LOSE")
        XCTAssertEqual(report.rounds[1].roundId, rounds[1].id)
        XCTAssertEqual(report.rounds[1].demands.count, 1)
        XCTAssertEqual(report.rounds[1].demands[0].networkId, demandId2)
        XCTAssertEqual(report.rounds[1].demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionFailureWithProgrammaticDemandNoBid() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidFailure(error: .noBid)
        }
        
        adaptersRepository.register(adapter: adapterMock1)

        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1],
                bidding: [""]
            )
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: []
        )

        controller.load {
            result = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")

        let report = mediationObserver.report

        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNil(report.result.winnerECPM)
        XCTAssertNil(report.result.winnerNetworkId)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_BID")
    }
    
    func testAuctionFailureWithProgrammaticDemandAndNoFillAnd() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let demandId2 = "demand_id_2"
        
        let eCPM1 = pricefloor * 1.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidSuccess(eCPM: eCPM1)
            builder.withStubbedFillFailure(error: .noFill)
        }
        
        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidFailure(error: .noBid)
        }

        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)

        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1],
                bidding: [""]
            ),
            AuctionRoundMock(
                id: "round_2",
                timeout: timeout,
                demands: [demandId2],
                bidding: [""]
            )
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: []
        )

        controller.load {
            result = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")

        let report = mediationObserver.report

        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNil(report.result.winnerECPM)
        XCTAssertNil(report.result.winnerNetworkId)

        XCTAssertEqual(report.rounds.count, 2)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_FILL")
        XCTAssertEqual(report.rounds[1].roundId, rounds[1].id)
        XCTAssertEqual(report.rounds[1].demands.count, 1)
        XCTAssertEqual(report.rounds[1].demands[0].networkId, demandId2)
        XCTAssertEqual(report.rounds[1].demands[0].status.stringValue, "NO_BID")
    }
}
