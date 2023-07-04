//
//  ConcurrentAuctionControllerTestCase+MixedDemand.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 04.07.2023.
//

import Foundation
import XCTest

@testable import Bidon


extension ConcurrentAuctionControllerTestCase {
    func testAuctionSuccessWithMixedDemand() {
        var result: TestAuctionResult!
        
        let pricefloor = self.pricefloor!
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"
        let biddingToken1 = "bidding_token_1"
        let biddingPayload1 = "bidding_payload_1"
        let eCPM1 = pricefloor * 1.5
        
        let demandId2 = "demand_id_2"
        let eCPM2 = pricefloor * 3
        let eCPM3 = pricefloor * 2.7

        let demandId3 = "demand_id_3"
        let eCPM4 = pricefloor * 1.2

        let lineItem1 = LineItemModel(
            id: demandId2,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId2,
            pricefloor: eCPM3,
            adUnitId: "ad_unit_id_2"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: BiddingDemandProviderMock.self
        ) { builder in
            builder.withBiddingContextSuccess(biddingToken1)
            builder.withExpectedPayload(biddingPayload1)
            builder.withStubbedPrepareSuccess(eCPM: eCPM1)
        }
        
        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem2)
            builder.withStubbedLoadSuccess(eCPM: lineItem2.pricefloor)
        }
        
        let adapterMock3 = AdapterMock(
            id: demandId3,
            provider: ProgrammaticDemandProviderMock.self
        ) { builder in
            builder.withExpectedPricefloor(pricefloor)
            builder.withStubbedBidSuccess(eCPM: eCPM4)
            builder.withStubbedFillSuccess()
        }
        
        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)
        adaptersRepository.register(adapter: adapterMock3)

        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId2, demandId3],
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
            lineItems: [
                lineItem1,
                lineItem2
            ]
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = mediationObserver.report
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerECPM, eCPM3)
        XCTAssertEqual(report.result.winnerNetworkId, demandId2)
        XCTAssertEqual(report.result.winnerAdUnitId, lineItem2.adUnitId)
        
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 2)
        
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId2)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].eCPM, eCPM3)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")

        XCTAssertEqual(report.rounds[0].sortedDemands[1].networkId, demandId3)
        XCTAssertEqual(report.rounds[0].sortedDemands[1].eCPM, eCPM4)
        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "LOSE")
        
        XCTAssertEqual(report.rounds[0].bidding?.networkId, demandId1)
        XCTAssertEqual(report.rounds[0].bidding?.status.stringValue, "LOSE")
    }
}
