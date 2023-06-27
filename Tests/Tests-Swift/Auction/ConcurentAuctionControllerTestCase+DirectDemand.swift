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
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        let eCPM = pricefloor * 3
        
        let lineItem = LineItemModel(
            id: UUID().uuidString,
            pricefloor: eCPM,
            adUnitId: "some ad unit"
        )
        
        var result: AuctionResult!
        
        let demandAdMock = DemandAdMock()
        demandAdMock.stubbedNetworkName = "test"
        demandAdMock.stubbedId = UUID().uuidString
        demandAdMock.stubbedECPM = eCPM
        
        let providerMock = DirectDemandProviderMock()
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
        
        controller = controller(with: rounds)
        
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
        
        let report = mediationObserver.report

        XCTAssertEqual(report.result.status, .success)
        XCTAssertEqual(report.result.winnerECPM, eCPM)
        XCTAssertEqual(report.result.winnerNetworkId, "test")
        XCTAssertEqual(report.result.winnerAdUnitId, "some ad unit")

        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, "round_1")
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, "test")
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "WIN")
    }
    
    func testAuctionFailureWithSingleDirectDemandWithoutLineItem() {
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        
        var result: AuctionResult!
        
        let demandAdMock = DemandAdMock()
        demandAdMock.stubbedNetworkName = "test"
        demandAdMock.stubbedId = UUID().uuidString
        demandAdMock.stubbedECPM = pricefloor * 3
        
        let providerMock = DirectDemandProviderMock()
        providerMock.stubbedLoad = { adUnit, response in
            response(.success(demandAdMock))
        }
        
        let adapterMock = AdapterMock()
        adapterMock.stubbedProvider = providerMock
        adapterMock.stubbedIdentifier = "test"
        adapterMock.stubbedName = "Test Adapter"
        adapterMock.stubbedSdkVersion = "1.0.0"
        adapterMock.stubbedAdapterVersion = "0"
          
        adaptersRepository.register(adapter: adapterMock)

        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: ["test"],
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
        case .success:
            XCTAssertTrue(false, "Auction result is expected to be failed")
        case .failure, .none:
            XCTAssertTrue(true)
        }
        
        let report = mediationObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, "round_1")
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, "test")
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_APPROPRIATE_AD_UNIT_ID")
    }
    
    func testAuctionFailureWithSingleDirectDemandNoFill() {
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        let eCPM = pricefloor * 3
        
        let lineItem = LineItemModel(
            id: UUID().uuidString,
            pricefloor: eCPM,
            adUnitId: "some ad unit"
        )
        
        var result: AuctionResult!
        
        let providerMock = DirectDemandProviderMock()
        providerMock.stubbedLoad = { adUnit, response in
            XCTAssertEqual(lineItem.adUnitId, adUnit)
            response(.failure(.noFill))
        }
        
        let adapterMock = AdapterMock()
        adapterMock.stubbedProvider = providerMock
        adapterMock.stubbedIdentifier = "test"
        adapterMock.stubbedName = "Test Adapter"
        adapterMock.stubbedSdkVersion = "1.0.0"
        adapterMock.stubbedAdapterVersion = "0"
          
        adaptersRepository.register(adapter: adapterMock)
        lineItemElectorMock.stubbedPopLineItemResult = lineItem
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: ["test"],
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
        case .success:
            XCTAssertTrue(false, "Auction result is expected to be failed")
        case .failure, .none:
            XCTAssertTrue(true)
        }
        
        let report = mediationObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, "round_1")
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, "test")
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "NO_FILL")
    }
    
    func testAuctionFailureWithSingleDirectDemandAdapterNotInitialized() {
        let expectation = XCTestExpectation(description: "Wait for auciton complete")
        let timeout: TimeInterval = 1
        let eCPM = pricefloor * 3
        
        let lineItem = LineItemModel(
            id: UUID().uuidString,
            pricefloor: eCPM,
            adUnitId: "some ad unit"
        )
        
        var result: AuctionResult!
        
        let providerMock = DirectDemandProviderMock()
        providerMock.stubbedLoad = { adUnit, response in
            XCTAssertEqual(lineItem.adUnitId, adUnit)
            response(.failure(.adapterNotInitialized))
        }
        
        let adapterMock = AdapterMock()
        adapterMock.stubbedProvider = providerMock
        adapterMock.stubbedIdentifier = "test"
        adapterMock.stubbedName = "Test Adapter"
        adapterMock.stubbedSdkVersion = "1.0.0"
        adapterMock.stubbedAdapterVersion = "0"
          
        adaptersRepository.register(adapter: adapterMock)
        lineItemElectorMock.stubbedPopLineItemResult = lineItem
        
        let rounds = [
            AuctionRoundMock(
                id: "round_1",
                timeout: timeout,
                demands: ["test"],
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
        case .success:
            XCTAssertTrue(false, "Auction result is expected to be failed")
        case .failure, .none:
            XCTAssertTrue(true)
        }
        
        let report = mediationObserver.report
        
        XCTAssertEqual(report.result.status, .fail)
        XCTAssertEqual(report.rounds.count, 1)
        XCTAssertEqual(report.rounds[0].roundId, "round_1")
        XCTAssertEqual(report.rounds[0].demands.count, 1)
        XCTAssertEqual(report.rounds[0].demands[0].networkId, "test")
        XCTAssertEqual(report.rounds[0].demands[0].status.stringValue, "ADAPTER_NOT_INITIALIZED")
    }
}
