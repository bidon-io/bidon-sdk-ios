//
//  ConcurrentAuctionControllerTestCase+MixedDemand.swift
//  Tests-Swift
//
//  Created by Bidon Team on 04.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


//extension ConcurrentAuctionControllerTestCase {
//    func testAuctionSuccessWithMixedDemand() {
//        var result: TestAuctionResult!
//
//        let pricefloor = self.pricefloor!
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 5
//
//        let demandId1 = "demand_id_1"
//        let biddingToken1: TestBiddingToken = "bidding_token_1"
//        let biddingPayload1: TestBiddingPayload = "bidding_payload_1"
//        let price1 = pricefloor * 1.5
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .bidding,
//            pricefloor: .unknown,
//            extras: "some_bidding_extras"
//        )
//        
//        let demandId2 = "demand_id_2"
//        let price2 = pricefloor * 3
//        let adUnit2 = TestAdUnit(
//            demandId: demandId2,
//            demandType: .direct,
//            pricefloor: .unknown,
//            extras: "some_pricfloor_extras"
//        )
//        
//        let demandId3 = "demand_id_3"
//        let price3 = pricefloor * 1.2
//
//        let adUnit3 = TestAdUnit(
//           demandId: demandId3,
//           demandType: .direct,
//           pricefloor: price3,
//           extras: "some_cpm_extras"
//       )
//
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestBiddingDemandProviderMock.self
//        ) { builder in
//            builder.withBiddingToken(biddingToken1)
//            builder.withExpectedPayload(biddingPayload1)
//            builder.withStubbedDemandAd(price: price1)
//        }
//
//        let adapterMock2 = AdapterMock(
//            demandId: demandId2,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit2.extras)
//            builder.withStubbedDemandAd(price: price2)
//        }
//
//        let adapterMock3 = AdapterMock(
//            demandId: demandId3,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit3.extras)
//            builder.withStubbedDemandAd(price: price3)
//        }
//
//        adaptersRepository.register(adapter: adapterMock1)
//        adaptersRepository.register(adapter: adapterMock2)
//        adaptersRepository.register(adapter: adapterMock3)
//
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [demandId2, demandId3],
//                bidding: [demandId1]
//            )
//        ]
//
//        let request = BidRequest(route: .bid)
//        let response = BidRequest.ResponseBody(bids: [
//            TestServerBid(price: price1, adUnit: adUnit1, ext: biddingPayload1)
//        ])
//
//        stubBidRequest(request) { builder in
//            XCTAssertEqual(builder.biddingToken(for: demandId1), biddingToken1)
//            XCTAssertEqual(builder.tokensCount, 1)
//        }
//
//        stubBidResponseSuccess(
//            request: request,
//            response: response
//        )
//
//        controller = controller(
//            rounds: rounds,
//            adUnits: [
//                adUnit1,
//                adUnit2,
//                adUnit3
//            ].map { $0.adUnit }
//        )
//
//        controller.load {
//            result = $0
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//
//        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
//
//        let report = auctionObserver.report
//
//        XCTAssertEqual(report.result.status, .success)
//        XCTAssertEqual(report.result.winner?.price, price2)
//        XCTAssertEqual(report.result.winner?.adUnit.uid, adUnit2.uid)
//        XCTAssertEqual(report.result.winner?.adUnit.demandId, adUnit2.demandId)
//        XCTAssertEqual(report.result.winner?.adUnit.demandType, .direct)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 2)
//
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].adUnit?.uid, adUnit2.uid)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].bid?.price, price2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
//
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].adUnit?.uid, adUnit3.uid)
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].adUnit?.demandId, adUnit3.demandId)
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].bid?.price, price3)
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "LOSE")
//
//        XCTAssertEqual(report.rounds[0].bidding?.demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].bidding?.demands[0].status.stringValue, "LOSE")
//    }
//}
