//
//  ConcurentAuctionControllerTestCase+DirectDemand.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 26.06.2023.
//

import Foundation
import XCTest

@testable import Bidon


extension ConcurrentAuctionControllerTestCase {
    func testAuctionSuccessWithSingleDirectDemand() {
        var result: TestAuctionResult!
        
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"
        let eCPM1 = pricefloor * 3
        
        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem1)
            builder.withStubbedLoadSuccess(eCPM: eCPM1)
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
        
        let lineItems = [lineItem1]

        controller = controller(
            rounds: rounds,
            lineItems: lineItems
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
        XCTAssertEqual(report.result.winnerAdUnitId, lineItem1.adUnitId)

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionFailureWithSingleDirectDemandWithoutLineItem() {
        var result: TestAuctionResult!
        
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        let demandId1 = "demand_id_1"
        let eCPM1 = pricefloor * 3
    
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withStubbedLoadSuccess(eCPM: eCPM1)
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
        
        let lineItems: [LineItem] = []
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
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
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_APPROPRIATE_AD_UNIT_ID")
    }
    
    func testAuctionFailureWithSingleDirectDemandNoFill() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"
        let eCPM1 = pricefloor * 3
        
        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem1)
            builder.withStubbedLoadFailure(error: .noFill)
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
        
        let lineItems: [LineItem] = [lineItem1]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
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
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_FILL")
    }
    
    func testAuctionFailureWithSingleDirectDemandAdapterNotInitialized() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"
        let eCPM1 = pricefloor * 3
        
        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem1)
            builder.withStubbedLoadFailure(error: .adapterNotInitialized)
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
        
        let lineItems: [LineItem] = [lineItem1]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
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
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "ADAPTER_NOT_INITIALIZED")
    }
    
    func testAuctionSuccessWithMutipleDirectDemandAdaptersSingleBidAndTimeout() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"
        let demandId2 = "demand_id_2"

        let eCPM1 = pricefloor * 3
        let eCPM2 = pricefloor * 3
        
        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId2,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_2"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem1)
            builder.withStubbedLoadSuccess(eCPM: eCPM1)
        }
        
        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: DirectDemandProviderMock.self
        )
        
        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1, demandId2],
                bidding: [""]
            )
        ]
        
        let lineItems: [LineItem] = [lineItem1, lineItem2]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = mediationObserver.report
        // Demands order in auction round report is not defined
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerECPM, eCPM1)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 2)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
        XCTAssertEqual(report.rounds[0].sortedDemands[1].networkId, demandId2)
        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "FILL_TIMEOUT_REACHED")
    }
    
    func testAuctionSuccessWithMutipleDirectDemandAdaptersAndMutipleBids() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"
        let demandId2 = "demand_id_2"

        let eCPM1 = pricefloor * 3
        let eCPM2 = pricefloor * 2

        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId2,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_2"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem1)
            builder.withStubbedLoadSuccess(eCPM: eCPM1)
        }
        
        let adapterMock2 = AdapterMock(
            id: demandId2,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem2)
            builder.withStubbedLoadSuccess(eCPM: eCPM2)
        }
        
        adaptersRepository.register(adapter: adapterMock1)
        adaptersRepository.register(adapter: adapterMock2)
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: [demandId1, demandId2],
                bidding: [""]
            )
        ]
        
        let lineItems: [LineItem] = [
            lineItem1,
            lineItem2
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
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
        XCTAssertEqual(report.result.winnerECPM, eCPM1)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 2)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
        XCTAssertEqual(report.rounds[0].sortedDemands[1].networkId, demandId2)
        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "LOSE")
    }
    
    func testShouldPickTheNearestMoreExpensiveLineItemAndTryingToLoadOnlyOnce() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"

        let eCPM1 = pricefloor * 3
        let eCPM2 = pricefloor * 1.5
        let eCPM3 = pricefloor * 0.99

        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_2"
        )
        
        let lineItem3 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM3,
            adUnitId: "ad_unit_id_3"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        ) { builder in
            builder.withExpectedLineItem(lineItem2)
            builder.withStubbedLoadSuccess(eCPM: eCPM2)
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
        
        let lineItems: [LineItem] = [
            lineItem1,
            lineItem2,
            lineItem3
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = mediationObserver.report
        
        XCTAssertEqual((adapterMock1.stubbedProvider as! DirectDemandProviderMock).invokedLoadCount, 1)
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerNetworkId, demandId1)
        XCTAssertEqual(report.result.winnerECPM, eCPM2)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].eCPM, eCPM2)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].adUnitId, lineItem2.adUnitId)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
    }
    
    func testShouldLoadLineItemsInEachRounds() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        let demandId1 = "demand_id_1"

        let eCPM1 = pricefloor * 3
        let eCPM2 = pricefloor * 1.5
        let eCPM3 = pricefloor * 0.99

        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_2"
        )
        
        let lineItem3 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM3,
            adUnitId: "ad_unit_id_3"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        )
        let providerMock1 = adapterMock1.stubbedProvider as! DirectDemandProviderMock
        providerMock1.stubbedLoad = { adUnitId, response in
            switch adUnitId {
            case lineItem1.adUnitId:
                let ad = DemandAdMock()
                ad.stubbedECPM = eCPM1
                ad.stubbedNetworkName = demandId1
                ad.stubbedId = UUID().uuidString
                response(.success(ad))
                break
            case lineItem2.adUnitId:
                let ad = DemandAdMock()
                ad.stubbedECPM = eCPM2
                ad.stubbedNetworkName = demandId1
                ad.stubbedId = UUID().uuidString
                response(.success(ad))
                break
            default:
                response(.failure(.noFill))
            }
        }
    
        adaptersRepository.register(adapter: adapterMock1)
        
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
                demands: [demandId1],
                bidding: [""]
            )
        ]
        
        let lineItems: [LineItem] = [
            lineItem1,
            lineItem2,
            lineItem3
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
        
        let report = mediationObserver.report
        
        XCTAssertEqual((adapterMock1.stubbedProvider as! DirectDemandProviderMock).invokedLoadCount, 2)
        
        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerNetworkId, demandId1)
        XCTAssertEqual(report.result.winnerECPM, eCPM1)
        XCTAssertEqual(report.rounds.count, 2)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].eCPM, eCPM2)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].adUnitId, lineItem2.adUnitId)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "LOSE")
        XCTAssertEqual(report.rounds[1].roundId, rounds[1].id)
        XCTAssertEqual(report.rounds[1].demands.count, 1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].eCPM, eCPM1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].adUnitId, lineItem1.adUnitId)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].status.stringValue, "WIN")
    }
    
    func testShouldRespondsOnAuctionCancelation() {
        var result: TestAuctionResult!

        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 5
        
        let demandId1 = "demand_id_1"

        let eCPM1 = pricefloor * 3
        let eCPM2 = pricefloor * 1.5
        let eCPM3 = pricefloor * 0.99

        let lineItem1 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM1,
            adUnitId: "ad_unit_id_1"
        )
        
        let lineItem2 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM2,
            adUnitId: "ad_unit_id_2"
        )
        
        let lineItem3 = LineItemModel(
            id: demandId1,
            pricefloor: eCPM3,
            adUnitId: "ad_unit_id_3"
        )
        
        let adapterMock1 = AdapterMock(
            id: demandId1,
            provider: DirectDemandProviderMock.self
        )
        let providerMock1 = adapterMock1.stubbedProvider as! DirectDemandProviderMock
        providerMock1.stubbedLoad = { [unowned self] adUnitId, response in
            switch adUnitId {
            case lineItem1.adUnitId:
                self.controller.cancel()
                break
            case lineItem2.adUnitId:
                response(.failure(.incorrectAdUnitId))
                break
            default:
                response(.failure(.noFill))
            }
        }
    
        adaptersRepository.register(adapter: adapterMock1)
        
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
                demands: [demandId1],
                bidding: [""]
            )
        ]
        
        let lineItems: [LineItem] = [
            lineItem1,
            lineItem2,
            lineItem3
        ]
        
        controller = controller(
            rounds: rounds,
            lineItems: lineItems
        )
        
        controller.load {
            result = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
        
        let report = mediationObserver.report
        
        XCTAssertEqual((adapterMock1.stubbedProvider as! DirectDemandProviderMock).invokedLoadCount, 2)
        
        XCTAssertEqual(report.result.status, .cancelled)
        XCTAssertNil(report.result.winnerNetworkId)
        XCTAssertNil(report.result.winnerECPM)
        
        XCTAssertEqual(report.rounds.count, 2)
        XCTAssertEqual(report.rounds[0].roundId, rounds[0].id)
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].adUnitId, lineItem2.adUnitId)
        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "INCORRECT_AD_UNIT_ID")
        XCTAssertEqual(report.rounds[1].roundId, rounds[1].id)
        XCTAssertEqual(report.rounds[1].demands.count, 1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].networkId, demandId1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].eCPM, eCPM1)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].adUnitId, lineItem1.adUnitId)
        XCTAssertEqual(report.rounds[1].sortedDemands[0].status.stringValue, "AUCTION_CANCELLED")
    }
}
