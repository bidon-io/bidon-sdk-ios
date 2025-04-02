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
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let price1 = pricefloor * 1.5
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "ad_unit_extras_1"
        )
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withExpectedAdUnitExtras(adUnit1.extras)
            builder.withStubbedDemandAd(price: price1)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.tokensCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winner?.price, price1)
        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId1)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.demands.count, 1)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].adUnit?.demandId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionFaileWithoutBiddingDemandAdUnit() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let price1 = pricefloor * 1.5
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "ad_unit_extras_1"
        )
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withExpectedAdUnitExtras(adUnit1.extras)
            builder.withStubbedDemandAd(price: price1)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.tokensCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: []
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNil(report.result.winner?.adUnit.demandId)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertNil(report.rounds[0].bidding)
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoBiddingContext() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let price1 = pricefloor * 1.5
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras"
        )
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withExpectedAdUnitExtras(adUnit1.extras)
            builder.withBiddingTokenError(.adapterNotInitialized)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.tokensCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNil(report.result.winner?.adUnit.demandId)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertNil(report.rounds[0].bidding)
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoBid() {
        var result: TestAuctionResult!
        
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras"
        )
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
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
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.tokensCount, 1)
        }
        
        stubBidResponseFailure(
            request: request,
            error: .invalidResponse
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNil(report.result.winner)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.demands.count, 0)
    }
    
    func testAuctionFailureWithSingleBiddingDemandNoFill() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let price1 = pricefloor * 1.5
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras"
        )
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedLoadingError(.noFill)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.tokensCount, 1)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].demandId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].adUnit?.uid, adUnit1.uid)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].status.stringValue, "NO_FILL")
    }
    
    func testAuctionSuccessWithMultipleBiddingDemands() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_1"
        )
        
        let demandId2 = "demand_id_2"
        let biddingToken2: TestBiddingToken = "bidding_token_2"
        let biddingPayload2: TestBiddingPayload = "bidding_payload_2"
        let adUnit2 = TestAdUnit(
            demandId: demandId2,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_2"
        )
        
        let demandId3 = "demand_id_3"
        let biddingToken3: TestBiddingToken = "bidding_token_3"
        let biddingPayload3: TestBiddingPayload = "bidding_payload_3"
        let adUnit3 = TestAdUnit(
            demandId: demandId3,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_3"
        )
        
        let price1 = pricefloor * 1.5
        let price2 = pricefloor * 2
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedDemandAd(price: price2)
        }
        
        let adapterMock2 = AdapterMock(
            demandId: demandId2,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken2)
            builder.withExpectedPayload(biddingPayload2)
            builder.withStubbedDemandAd(price: price1)
        }
        
        let adapterMock3 = AdapterMock(
            demandId: demandId3,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken3)
            builder.withExpectedPayload(biddingPayload3)
            builder.withStubbedDemandAd(price: price1)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price2, adUnit: adUnit1, ext: biddingPayload1)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.biddingToken(for: demandId2), biddingToken2)
            XCTAssertEqual(builder.biddingToken(for: demandId3), biddingToken3)
            XCTAssertEqual(builder.tokensCount, 3)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1, adUnit2, adUnit3].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId1)
        XCTAssertEqual(report.result.winner?.price, price2)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.demands.count, 1)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].demandId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionSuccessWithMultipleBids() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1: TestBiddingToken = "bidding_token_1"
        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
        let adUnit1 = TestAdUnit(
            demandId: demandId1,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_1"
        )
        
        let demandId2 = "demand_id_2"
        let biddingToken2: TestBiddingToken = "bidding_token_2"
        let biddingPayload2: TestBiddingPayload = "bidding_payload_2"
        let adUnit2 = TestAdUnit(
            demandId: demandId2,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_2"
        )
        
        let demandId3 = "demand_id_3"
        let biddingToken3: TestBiddingToken = "bidding_token_3"
        let biddingPayload3: TestBiddingPayload = "bidding_payload_3"
        let adUnit3 = TestAdUnit(
            demandId: demandId3,
            demandType: .bidding,
            pricefloor: .unknown,
            extras: "some_extras_3"
        )
        
        let price1 = pricefloor * 2
        let price2 = pricefloor * 1.5
        let price3 = pricefloor * 1.25
        
        let adapterMock1 = AdapterMock(
            demandId: demandId1,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedLoadingError(.noFill)
        }
        
        let adapterMock2 = AdapterMock(
            demandId: demandId2,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken2)
            builder.withExpectedPayload(biddingPayload2)
            builder.withStubbedDemandAd(price: price2)
        }
        
        let adapterMock3 = AdapterMock(
            demandId: demandId3,
            provider: TestBiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingToken(biddingToken3)
            builder.withExpectedPayload(biddingPayload3)
            builder.withStubbedDemandAd(price: price3)
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
        let response = BidRequest.ResponseBody(bids: [
            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1),
            TestServerBid(price: price2, adUnit: adUnit2, ext: biddingPayload2),
            TestServerBid(price: price3, adUnit: adUnit3, ext: biddingPayload3)
        ])
        
        stubBidRequest(request) { builder in
            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
            XCTAssertEqual(builder.biddingToken(for: demandId2), biddingToken2)
            XCTAssertEqual(builder.biddingToken(for: demandId3), biddingToken3)
            XCTAssertEqual(builder.tokensCount, 3)
        }
        
        stubBidResponseSuccess(
            request: request,
            response: response
        )
        
        controller = controller(
            rounds: rounds,
            adUnits: [adUnit1, adUnit2, adUnit3].map { $0.adUnit }
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = auctionObserver.report
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId2)
        XCTAssertEqual(report.result.winner?.price, price2)
        XCTAssertEqual(report.result.winner?.adUnit.demandType, .bidding)
        XCTAssertNotZero(report.result.startTimestamp)
        XCTAssertNotZero(report.result.finishTimestamp)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 0)
        XCTAssertEqual(report.rounds[0].bidding?.demands.count, 3)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].adUnit?.uid, adUnit1.uid)
        XCTAssertEqual(report.rounds[0].bidding?.demands[0].status.stringValue, "NO_FILL")
        XCTAssertEqual(report.rounds[0].bidding?.demands[1].adUnit?.uid, adUnit2.uid)
        XCTAssertEqual(report.rounds[0].bidding?.demands[1].status.stringValue, "WIN")
        XCTAssertEqual(report.rounds[0].bidding?.demands[2].adUnit?.uid, adUnit3.uid)
        XCTAssertEqual(report.rounds[0].bidding?.demands[2].status.stringValue, "LOSE")
    }
}
