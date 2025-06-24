//
//  ConcurentAuctionControllerTestCase+DirectDemand.swift
//  Tests-Swift
//
//  Created by Bidon Team on 26.06.2023.
//

import Foundation
import XCTest

@testable import Bidon


//extension ConcurrentAuctionControllerTestCase {
//    func testAuctionSuccessWithSingleDirectDemand() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        let price1 = pricefloor * 3
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "some_extras"
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
//            )
//        ]
//        
//        controller = controller(
//            rounds: rounds,
//            adUnits: [adUnit1.adUnit]
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
//        XCTAssertEqual(report.result.winner?.price, price1)
//        XCTAssertEqual(report.result.winner?.adUnit.uid, adUnit1.uid)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        XCTAssertGreaterThanOrEqual(report.result.finishTimestamp, report.result.startTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "WIN")
//    }
//    
//    func testAuctionSuccessWithSingleDirectDemandOverridePrice() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        let price1 = pricefloor * 3
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: .unknown,
//            extras: "some_extras"
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
//            )
//        ]
//        
//        controller = controller(
//            rounds: rounds,
//            adUnits: [adUnit1.adUnit]
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
//        XCTAssertEqual(report.result.winner?.price, price1)
//        XCTAssertEqual(report.result.winner?.adUnit.uid, adUnit1.uid)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].bid?.price, price1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "WIN")
//    }
//    
//    func testAuctionFailureWithSingleDirectDemandWithoutAdUnit() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        let demandId1 = "demand_id_1"
//        let price1 = pricefloor * 3
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
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
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = []
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        
//        XCTAssertEqual(report.result.status, .fail)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_APPROPRIATE_AD_UNIT_ID")
//    }
//    
//    func testAuctionFailureWithSingleDirectDemandNoApropriateAdUnitType() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        let demandId1 = "demand_id_1"
//        let price1 = pricefloor * 3
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .bidding,
//            pricefloor: price1,
//            extras: "some_extras"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
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
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [adUnit1].map { $0.adUnit }
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        
//        XCTAssertEqual(report.result.status, .fail)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_APPROPRIATE_AD_UNIT_ID")
//    }
//    
//    func testAuctionFailureWithSingleDirectDemandNoFill() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
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
//            builder.withExpectedAdUnitExtras(adUnit1.extras)
//            builder.withStubbedLoadingError(.noFill)
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
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [adUnit1].map { $0.adUnit }
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        
//        XCTAssertEqual(report.result.status, .fail)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_FILL")
//    }
//    
//    func testAuctionFailureWithSingleDirectDemandAdapterNotInitialized() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
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
//            builder.withExpectedAdUnitExtras(adUnit1.extras)
//            builder.withStubbedLoadingError(.adapterNotInitialized)
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
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [adUnit1].map { $0.adUnit }
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        
//        XCTAssertEqual(report.result.status, .fail)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].demands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "ADAPTER_NOT_INITIALIZED")
//    }
//    
//    func testAuctionSuccessWithMutipleDirectDemandAdaptersSingleBidAndTimeout() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        let demandId2 = "demand_id_2"
//        
//        let price1 = pricefloor * 3
//        let price2 = pricefloor * 3
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adUnit2 = TestAdUnit(
//            demandId: demandId2,
//            demandType: .direct,
//            pricefloor: price2,
//            extras: "ad_unit_extras_2"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit1.extras)
//            builder.withStubbedDemandAd(price: price1)
//        }
//        
//        let adapterMock2 = AdapterMock(
//            demandId: demandId2,
//            provider: TestDirectDemandProviderMock.self
//        )
//        
//        adaptersRepository.register(adapter: adapterMock1)
//        adaptersRepository.register(adapter: adapterMock2)
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [demandId1, demandId2],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [adUnit1, adUnit2].map { $0.adUnit }
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
//        
//        let report = auctionObserver.report
//        // Demands order in auction round report is not defined
//        
//        XCTAssertEqual(report.result.status, .success)
//        XCTAssertEqual(report.result.winner?.price, price1)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].demandId, demandId2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "FILL_TIMEOUT_REACHED")
//    }
//    
//    func testAuctionSuccessWithMutipleDirectDemandAdaptersAndMutipleBids() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        let demandId2 = "demand_id_2"
//        
//        let price1 = pricefloor * 3
//        let price2 = pricefloor * 2
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adUnit2 = TestAdUnit(
//            demandId: demandId2,
//            demandType: .direct,
//            pricefloor: price2,
//            extras: "ad_unit_extras_2"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit1.extras)
//            builder.withStubbedDemandAd(price: price1)
//        }
//        
//        let adapterMock2 = AdapterMock(
//            demandId: demandId2,
//            provider: DirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit2.extras)
//            builder.withStubbedDemandAd(price: price2)
//        }
//        
//        adaptersRepository.register(adapter: adapterMock1)
//        adaptersRepository.register(adapter: adapterMock2)
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [demandId1, demandId2],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [
//            adUnit1,
//            adUnit2
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
//        
//        let report = auctionObserver.report
//        
//        XCTAssertEqual(report.result.status, .success)
//        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId1)
//        XCTAssertEqual(report.result.winner?.price, price1)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].demandId, demandId2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[1].status.stringValue, "LOSE")
//    }
//    
//    func testShouldPickTheNearestMoreExpensiveAdUnitAndTryingToLoadOnlyOnce() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        
//        let price1 = pricefloor * 3
//        let price2 = pricefloor * 1.5
//        let price3 = pricefloor * 0.99
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adUnit2 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price2,
//            extras: "ad_unit_extras_2"
//        )
//        
//        let adUnit3 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price3,
//            extras: "ad_unit_extras_3"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        ) { builder in
//            builder.withExpectedAdUnitExtras(adUnit2.extras)
//            builder.withStubbedDemandAd(price: price2)
//        }
//        
//        
//        adaptersRepository.register(adapter: adapterMock1)
//        
//        let rounds = [
//            AuctionRoundMock(
//                id: "round_1",
//                timeout: timeout,
//                demands: [demandId1],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [
//            adUnit1,
//            adUnit2,
//            adUnit3
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
//        
//        let report = auctionObserver.report
//        let provider = (adapterMock1.stubbedProvider as! TestDirectDemandProviderMock)
//        XCTAssertEqual(provider.invokedLoadPricefloorAdUnitExtrasCount, 1)
//        
//        XCTAssertEqual(report.result.status, .success)
//        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId1)
//        XCTAssertEqual(report.result.winner?.price, price2)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 1)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].bid?.price, price2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].bid?.adUnit.uid, adUnit2.uid)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "WIN")
//    }
//    
//    func testShouldLoadAdUnitsInEachRounds() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 1
//        
//        let demandId1 = "demand_id_1"
//        
//        let price1 = pricefloor * 3
//        let price2 = pricefloor * 1.5
//        let price3 = pricefloor * 0.99
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adUnit2 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price2,
//            extras: "ad_unit_extras_2"
//        )
//        
//        let adUnit3 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price3,
//            extras: "ad_unit_extras_3"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        )
//        
//        let providerMock1 = adapterMock1.stubbedProvider as! TestDirectDemandProviderMock
//        
//        providerMock1._load = { _, extras, response in
//            switch extras {
//            case adUnit1.extras:
//                let ad = DemandAdMock()
//                ad.stubbedPrice = price1
//                ad.stubbedId = UUID().uuidString
//                response(.success(ad))
//                break
//            case adUnit2.extras:
//                let ad = DemandAdMock()
//                ad.stubbedPrice = price2
//                ad.stubbedId = UUID().uuidString
//                response(.success(ad))
//                break
//            default:
//                response(.failure(.noFill))
//            }
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
//            AuctionRoundMock(
//                id: "round_2",
//                timeout: timeout,
//                demands: [demandId1],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [
//            adUnit1,
//            adUnit2,
//            adUnit3
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertTrue(result.isSuccess, "Auction result is expected to be success")
//        
//        let report = auctionObserver.report
//        let provider = (adapterMock1.stubbedProvider as! TestDirectDemandProviderMock)
//        XCTAssertEqual(provider.invokedLoadPricefloorAdUnitExtrasCount, 2)
//        
//        XCTAssertEqual(report.result.status, .success)
//        XCTAssertEqual(report.result.winner?.adUnit.demandId, demandId1)
//        XCTAssertEqual(report.result.winner?.price, price1)
//        XCTAssertEqual(report.result.winner?.adUnit.demandType, .direct)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//        
//        XCTAssertEqual(report.rounds.count, 2)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].bid?.price, price2)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].bid?.adUnit.uid, adUnit2.uid)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "LOSE")
//        XCTAssertEqual(report.rounds[1].configuration.roundId, rounds[1].id)
//        XCTAssertEqual(report.rounds[1].demands.count, 1)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].bid?.price, price1)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].bid?.adUnit.uid, adUnit1.uid)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].status.stringValue, "WIN")
//    }
//    
//    func testShouldRespondsOnAuctionCancelation() {
//        var result: TestAuctionResult!
//        
//        let expectation = XCTestExpectation(description: "Wait for auciton complete")
//        let timeout: TimeInterval = 5
//        
//        let demandId1 = "demand_id_1"
//        
//        let price1 = pricefloor * 3
//        let price2 = pricefloor * 1.5
//        let price3 = pricefloor * 0.99
//        
//        let adUnit1 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price1,
//            extras: "ad_unit_extras_1"
//        )
//        
//        let adUnit2 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price2,
//            extras: "ad_unit_extras_2"
//        )
//        
//        let adUnit3 = TestAdUnit(
//            demandId: demandId1,
//            demandType: .direct,
//            pricefloor: price3,
//            extras: "ad_unit_extras_3"
//        )
//        
//        let adapterMock1 = AdapterMock(
//            demandId: demandId1,
//            provider: TestDirectDemandProviderMock.self
//        )
//        let providerMock1 = adapterMock1.stubbedProvider as! TestDirectDemandProviderMock
//        providerMock1._load = { [unowned self] _, extras, response in
//            switch extras {
//            case adUnit1.extras:
//                self.controller.cancel()
//                break
//            case adUnit2.extras:
//                response(.failure(.incorrectAdUnitId))
//                break
//            default:
//                response(.failure(.noFill))
//            }
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
//            AuctionRoundMock(
//                id: "round_2",
//                timeout: timeout,
//                demands: [demandId1],
//                bidding: [""]
//            )
//        ]
//        
//        let adUnits: [AdUnitModel] = [
//            adUnit1,
//            adUnit2,
//            adUnit3
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
//        
//        wait(for: [expectation], timeout: timeout)
//        
//        XCTAssertFalse(result.isSuccess, "Auction result is expected to be failed")
//        
//        let report = auctionObserver.report
//        let provider = (adapterMock1.stubbedProvider as! TestDirectDemandProviderMock)
//        XCTAssertEqual(provider.invokedLoadPricefloorAdUnitExtrasCount, 2)
//        
//        XCTAssertEqual(report.result.status, .cancelled)
//        XCTAssertNil(report.result.winner)
//        XCTAssertNotZero(report.result.startTimestamp)
//        XCTAssertNotZero(report.result.finishTimestamp)
//
//        XCTAssertEqual(report.rounds.count, 2)
//        XCTAssertEqual(report.rounds[0].configuration.roundId, rounds[0].id)
//        XCTAssertEqual(report.rounds[0].demands.count, 1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].adUnit?.uid, adUnit2.uid)
//        XCTAssertEqual(report.rounds[0].sortedDemands[0].status.stringValue, "INCORRECT_AD_UNIT_ID")
//        XCTAssertEqual(report.rounds[1].configuration.roundId, rounds[1].id)
//        XCTAssertEqual(report.rounds[1].demands.count, 1)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].demandId, demandId1)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].adUnit?.uid, adUnit1.uid)
//        XCTAssertEqual(report.rounds[1].sortedDemands[0].status.stringValue, "AUCTION_CANCELLED")
//    }
//}
