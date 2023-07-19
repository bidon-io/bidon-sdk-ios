//
//  ConcurrentAuctionControllerTestCase+BiddingDemand.swift
//  Tests-Swift
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


extension ConcurrentAuctionControllerTestCase {
    func testAuctionSuccessWithSingleBiddingDemand() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"
        let biddingPayload1 = "bidding_payload_1"
        let eCPM1 = pricefloor * 1.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedPrepareSuccess(eCPM: eCPM1)
        }

        adaptersRepository.register(adapter: adapterMock1)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [],
                bidding: [demandId1]
            )
        ]
        
        let request = BidRequest(route: .bid)
        let response = BidRequest.ResponseBody(
            bid: .init(
                id: UUID().uuidString,
                impressionId: UUID().uuidString,
                price: eCPM1,
                demandId: demandId1,
                payload: biddingPayload1
            )
        )
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingContext(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.demandsCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
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
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.networkId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.status.stringValue, "WIN")
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoBiddingContext() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"
        let biddingPayload1 = "bidding_payload_1"
        let eCPM1 = pricefloor * 1.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextFailure(.adapterNotInitialized)
        }

        adaptersRepository.register(adapter: adapterMock1)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [],
                bidding: [demandId1]
            )
        ]
        
        let request = BidRequest(route: .bid)
        let response = BidRequest.ResponseBody(
            bid: .init(
                id: UUID().uuidString,
                impressionId: UUID().uuidString,
                price: eCPM1,
                demandId: demandId1,
                payload: biddingPayload1
            )
        )
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingContext(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.demandsCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
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
        XCTAssertNil(report.result.winnerNetworkId)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertNil(report.rounds[0].bidding)
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoBid() {
        var result: TestAuctionResult!
        
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken1)
        }

        adaptersRepository.register(adapter: adapterMock1)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [],
                bidding: [demandId1]
            )
        ]
        
        let request = BidRequest(route: .bid)
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingContext(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.demandsCount, 1)
        }
        
        stubBidResponseFailure(
            request: request,
            error: .invalidResponse
        )
        
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
        XCTAssertNil(report.result.winnerNetworkId)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.status.stringValue, "NO_BID")
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoFill() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"
        let biddingPayload1 = "bidding_payload_1"
        let eCPM1 = pricefloor * 1.5

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedPrepareFailure(error: .noFill)
        }

        adaptersRepository.register(adapter: adapterMock1)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [],
                bidding: [demandId1]
            )
        ]
        
        let request = BidRequest(route: .bid)
        let response = BidRequest.ResponseBody(
            bid: .init(
                id: UUID().uuidString,
                impressionId: UUID().uuidString,
                price: eCPM1,
                demandId: demandId1,
                payload: biddingPayload1
            )
        )
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingContext(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.demandsCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
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

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.networkId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.status.stringValue, "NO_FILL")
    }
    
    func testAuctionSuccessWithMultipleBiddingDemands() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"
        let biddingPayload1 = "bidding_payload_1"
        
        let demandId2 = "demand_id_2"
        let biddingToken2 = "bidding_token_2"
        let biddingPayload2 = "bidding_payload_2"
        
        let demandId3 = "demand_id_3"
        let biddingToken3 = "bidding_token_3"
        let biddingPayload3 = "bidding_payload_3"
        
        let eCPM1 = pricefloor * 1.5
        let eCPM2 = pricefloor * 2

        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedPrepareSuccess(eCPM: eCPM2)
        }

        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken2)
            builder.withExpectedPayload(biddingPayload2)
            builder.withStubbedPrepareSuccess(eCPM: eCPM1)
        }
        
        let adapterMock3 = AdapterMock(
            id: demandId3,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken3)
            builder.withExpectedPayload(biddingPayload3)
            builder.withStubbedPrepareSuccess(eCPM: eCPM1)
        }

        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)
        adaptersRepository.register(adapter: adapterMock3)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [],
                bidding: [demandId1, demandId2, demandId3]
            )
        ]
        
        let request = BidRequest(route: .bid)
        let response = BidRequest.ResponseBody(
            bid: .init(
                id: UUID().uuidString,
                impressionId: UUID().uuidString,
                price: eCPM2,
                demandId: demandId1,
                payload: biddingPayload1
            )
        )
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingContext(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.biddingContext(for: demandId2), biddingToken2)
            XCTAssertEqual(builder.biddingContext(for: demandId3), biddingToken3)
            XCTAssertEqual(builder.demandsCount, 3)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
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
        XCTAssertEqual(report.result.winnerNetworkId, demandId1)
        XCTAssertEqual(report.result.winnerECPM, eCPM2)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.networkId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.status.stringValue, "WIN")
    }
}
