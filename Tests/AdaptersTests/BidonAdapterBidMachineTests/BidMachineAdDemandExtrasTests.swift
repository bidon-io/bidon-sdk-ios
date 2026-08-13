//
//  BidMachineAdDemandExtrasTests.swift
//  BidonAdapterBidMachineTests
//
//  Created by Bidon Team on 13.08.2026.
//

import Testing
import Foundation
import UIKit
import BidMachine
import Bidon

@testable import BidonAdapterBidMachine


@Suite
struct BidMachineAdDemandExtrasTests {

    private final class AuctionResponseMock: NSObject, BidMachineAuctionResponseProtocol {
        let bidId: String = "bid123"
        let creativeId: String? = nil
        let dealId: String? = nil
        let cId: String? = nil
        let demandSource: String = "test_demand"
        let price: Double = 2.75
        let customParams: [String: Any]
        let customExtras: [String: Any] = [:]

        init(customParams: [String: Any]) {
            self.customParams = customParams
            super.init()
        }
    }

    private final class BidMachineAdMock: NSObject, BidMachineAdProtocol {
        var rendererConfiguration: BidMachineRendererConfiguration {
            fatalError("Not used in tests")
        }
        var auctionRequest: BidMachineAuctionRequest {
            fatalError("Not used in tests")
        }
        let auctionInfo: BidMachineAuctionResponseProtocol
        var controller: UIViewController?
        var delegate: BidMachineAdDelegate?
        var canShow: Bool { false }

        func loadAd() {}

        init(auctionInfo: BidMachineAuctionResponseProtocol) {
            self.auctionInfo = auctionInfo
            super.init()
        }
    }

    @Test
    func relaysCustomParamsAsAdditionalAdUnitExtras() {
        let ad = BidMachineAdMock(
            auctionInfo: AuctionResponseMock(customParams: [
                "custom_param": "custom123",
                "another_param": "another123"
            ])
        )
        let demand = BidMachineAdDemand(ad)

        let extras = demand.additionalAdUnitExtras

        #expect(extras?.count == 2)
        #expect(extras?["custom_param"]?.value as? String == "custom123")
        #expect(extras?["another_param"]?.value as? String == "another123")
    }

    @Test
    func returnsNilWhenBidCarriesNoCustomParams() {
        let ad = BidMachineAdMock(
            auctionInfo: AuctionResponseMock(customParams: [:])
        )
        let demand = BidMachineAdDemand(ad)

        #expect(demand.additionalAdUnitExtras == nil)
    }
}
