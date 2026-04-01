//
//  AdCacheIntegrationTests.swift
//  Tests
//

import XCTest
@testable import Bidon

// MARK: - §9: Bid Status Tests

final class AdCacheStatusTests: XCTestCase {

    func testCacheStatusStringValue() {
        XCTAssertEqual(DemandMediationStatus.cache.stringValue, "CACHE")
    }

    func testCacheStatusIsNotUnknown() {
        XCTAssertFalse(DemandMediationStatus.cache.isUnknown)
    }

    func testCacheStatusIsNotCancelled() {
        XCTAssertFalse(DemandMediationStatus.cache.isCancelled)
    }

    func testCacheStatusEncoding() throws {
        let data = try JSONEncoder().encode(DemandMediationStatus.cache)
        XCTAssertEqual(String(data: data, encoding: .utf8), "\"CACHE\"")
    }

    func testCacheStatusDecoding() throws {
        let data = "\"CACHE\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(DemandMediationStatus.self, from: data)
        XCTAssertEqual(status.stringValue, "CACHE")
    }

    func testAllStatusStringValues() {
        XCTAssertEqual(DemandMediationStatus.unknown.stringValue, "UNKNOWN")
        XCTAssertEqual(DemandMediationStatus.win.stringValue, "WIN")
        XCTAssertEqual(DemandMediationStatus.lose.stringValue, "LOSE")
        XCTAssertEqual(DemandMediationStatus.cache.stringValue, "CACHE")
    }
}

// MARK: - §9: DemandObservation.didCacheBid

final class AdCacheDemandObservationTests: XCTestCase {

    func testDidCacheBid_MarksMatchingEntry() {
        var observation = DemandObservation(tokens: [])

        let adUnit = makeAdUnit(uid: "u1", demandId: "applovin")
        let bid = makeBid(adUnit: adUnit, price: 10)

        observation.willLoadAdUnit(adUnit)
        observation.didReceiveClientBid(bid)

        // Before: unknown
        XCTAssertEqual(observation.entries.first?.status.stringValue, "UNKNOWN")

        observation.didCacheBid(bid)

        // After: cache
        XCTAssertEqual(observation.entries.first?.status.stringValue, "CACHE")
    }

    func testDidCacheBid_OnlyAffectsMatchingEntry() {
        var observation = DemandObservation(tokens: [])

        let a1 = makeAdUnit(uid: "u1", demandId: "applovin")
        let a2 = makeAdUnit(uid: "u2", demandId: "admob")
        let b1 = makeBid(adUnit: a1, price: 10)
        let b2 = makeBid(adUnit: a2, price: 8)

        observation.willLoadAdUnit(a1)
        observation.didReceiveClientBid(b1)
        observation.willLoadAdUnit(a2)
        observation.didReceiveClientBid(b2)

        observation.didCacheBid(b1) // only cache b1

        let e1 = observation.entries.first(where: { $0.adUnit?.uid == "u1" })
        let e2 = observation.entries.first(where: { $0.adUnit?.uid == "u2" })

        XCTAssertEqual(e1?.status.stringValue, "CACHE")
        XCTAssertEqual(e2?.status.stringValue, "UNKNOWN")
    }

    // MARK: - Helpers

    private func makeAdUnit(uid: String, demandId: String) -> AdUnitModel {
        return try! JSONDecoder().decode(AdUnitModel.self, from: """
        {
            "uid": "\(uid)",
            "demandId": "\(demandId)",
            "bidType": "CPM",
            "label": "\(demandId)",
            "pricefloor": 0,
            "ext": {},
            "timeout": 10000
        }
        """.data(using: .utf8)!)
    }

    private func makeBid(adUnit: AdUnitModel, price: Price) -> BidModel<DemandProviderMock> {
        return BidModel<DemandProviderMock>(
            id: adUnit.uid,
            impressionId: "",
            adType: .interstitial,
            adUnit: adUnit,
            price: price,
            ad: DemandAdMock(),
            provider: DemandProviderMock(),
            roundPricefloor: 0,
            auctionConfiguration: AuctionConfiguration(
                auctionId: "test",
                auctionConfigurationUid: "",
                auctionConfigurationId: 0,
                adUnits: [],
                segment: nil,
                token: nil,
                pricefloor: 0,
                auctionTimeout: 30000,
                tokens: [],
                isExternalNotificationsEnabled: false
            )
        )
    }
}

// MARK: - §10: AuctionInfo Tests

final class AdCacheAuctionInfoTests: XCTestCase {

    private func makeBidContainer(demandId: String, price: Price) -> BidContainer {
        let adUnit = BidContainer.AdNetworkUnitModel(
            uid: demandId,
            demandId: demandId,
            label: demandId,
            pricefloor: price,
            bidType: .cpm,
            extras: [:]
        )
        return BidContainer(
            id: demandId,
            adType: .interstitial,
            price: price,
            currencyCode: nil,
            networkName: demandId,
            dsp: nil,
            auctionId: "",
            adUnit: adUnit,
            bid: DummyAnyBid(demandId: demandId, price: price)
        )
    }

    // MARK: - appendWinReport

    func testAppendWinReport_CreatesWinEntry() {
        let info = DefaultAuctionInfo()
        info.appendWinReport(for: makeBidContainer(demandId: "applovin", price: 10))

        XCTAssertEqual(info.adUnits?.count, 1)
        XCTAssertEqual(info.adUnits?.first?.demandId, "applovin")
        XCTAssertEqual(info.adUnits?.first?.status, "WIN")
    }

    func testAppendWinReport_Accumulates() {
        let info = DefaultAuctionInfo()
        info.appendWinReport(for: makeBidContainer(demandId: "A", price: 10))
        info.appendWinReport(for: makeBidContainer(demandId: "B", price: 8))
        XCTAssertEqual(info.adUnits?.count, 2)
    }

    // MARK: - markOrAppendWin

    func testMarkOrAppendWin_UpdatesExisting() {
        let info = DefaultAuctionInfo()

        // Pre-populate with a LOSE entry that has matching demandId + uid
        let existingAd = makeBidContainer(demandId: "applovin", price: 5)
        info.appendWinReport(for: existingAd)
        // Change status to LOSE to simulate auction result
        (info.adUnits?.first as? DefaultAdUnitInfo)?.status = DemandMediationStatus.lose.stringValue
        XCTAssertEqual(info.adUnits?.first?.status, "LOSE")

        // markOrAppendWin should find by demandId+uid and update to WIN
        info.markOrAppendWin(for: makeBidContainer(demandId: "applovin", price: 5))

        XCTAssertEqual(info.adUnits?.count, 1)
        XCTAssertEqual(info.adUnits?.first?.status, "WIN")
    }

    func testMarkOrAppendWin_AppendsWhenNotFound() {
        let info = DefaultAuctionInfo()
        info.adUnits = []

        info.markOrAppendWin(for: makeBidContainer(demandId: "new", price: 5))

        XCTAssertEqual(info.adUnits?.count, 1)
        XCTAssertEqual(info.adUnits?.first?.demandId, "new")
        XCTAssertEqual(info.adUnits?.first?.status, "WIN")
    }

    // MARK: - §10: Cache hit → synthetic AuctionInfo

    func testCacheHit_SyntheticAuctionInfo() {
        let info = DefaultAuctionInfo()
        info.appendWinReport(for: makeBidContainer(demandId: "applovin", price: 30))

        XCTAssertEqual(info.auctionId, "") // no real auction
        XCTAssertEqual(info.adUnits?.count, 1)
        XCTAssertEqual(info.adUnits?.first?.status, "WIN")
    }

    // MARK: - §10: adUnits overwritten

    func testAdUnitsOverwrittenByAuctionResults() {
        let info = DefaultAuctionInfo()
        info.appendWinReport(for: makeBidContainer(demandId: "old", price: 10))
        XCTAssertEqual(info.adUnits?.count, 1)

        // Auction completes → overwrite
        info.adUnits = [
            DefaultAdUnitInfo(AuctionDemandReportModel(
                demandId: "B", status: .win, bid: nil, adUnit: nil,
                startTimestamp: 0, finishTimestamp: 0,
                tokenStartTimestamp: 0, tokenFinishTimestamp: 0
            ))
        ]

        XCTAssertEqual(info.adUnits?.count, 1)
        XCTAssertEqual(info.adUnits?.first?.demandId, "B")
    }
}

// MARK: - §6/§8/§15.1A: State & Auction Control

final class AdCacheStateTests: XCTestCase {

    private func makeStorage(
        cacheSize: Int, threshold: Int, fallbackSize: Int
    ) -> AdCacheStorage {
        return AdCacheStorage(
            main: CacheStorage(capacity: cacheSize, threshold: threshold, tag: "test"),
            fallback: FallbackCacheStorage(capacity: fallbackSize, tag: "test")
        )
    }

    // MARK: - §6/§15.1A: Silent return precondition

    /// When Main is not empty, loadAd returns from cache (no auction).
    /// This is the precondition check that prevents double-auction.
    func testSilentReturn_MainNotEmpty_NoAuction() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 1)
        s.route(MockAd(demandId: "A", price: 10), sticky: true)

        // Main has ad → ad manager returns from cache, skips auction
        XCTAssertNotNil(s.peekMain())
    }

    func testSilentReturn_MainEmpty_NeedsAuction() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 1)

        // Main empty → ad manager delegates to super which checks state
        XCTAssertNil(s.peekMain())
    }

    // MARK: - §8: show() → cancel auction precondition

    /// show() pops from cache. If auction is still running,
    /// manager sets auction=nil after cancel.
    func testShow_PopExhaustsCache() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 0)
        s.route(MockAd(demandId: "A", price: 10), sticky: true)
        s.route(MockAd(demandId: "B", price: 9), sticky: false)

        s.popFirst() // show $10
        s.popFirst() // show $9

        // Cache empty → manager would set state to .idle
        XCTAssertTrue(s.main.isEmpty)
        XCTAssertNil(s.peekMain())
    }

    // MARK: - §8: Cached bids not lost on cancel

    func testCachedBidsPreservedAfterPartialAuction() {
        let s = makeStorage(cacheSize: 3, threshold: 70, fallbackSize: 2)

        // Simulate partial auction: 3 bids arrived before cancel
        s.route(MockAd(demandId: "A", price: 8), sticky: true)
        s.route(MockAd(demandId: "B", price: 7), sticky: false)
        s.route(MockAd(demandId: "C", price: 6), sticky: false)

        // "cancel" happens here (remaining ad units not queried)
        // But cached bids are preserved
        XCTAssertEqual(s.peekMain()?.price, 8)
        XCTAssertEqual(s.popFirst()?.price, 8)
        XCTAssertEqual(s.popFirst()?.price, 7)
        XCTAssertEqual(s.popFirst()?.price, 6)
    }
}

// MARK: - Test Helpers

private final class MockAd: NSObject, Ad {
    var id: String
    var adType: AdType = .interstitial
    var price: Price
    var currencyCode: Currency?
    var networkName: String
    var dsp: String?
    var auctionId: String = ""
    var adUnit: AdNetworkUnit

    init(demandId: String, price: Price) {
        self.id = demandId
        self.price = price
        self.networkName = demandId
        self.adUnit = MockAdNetworkUnit(demandId: demandId, pricefloor: price)
    }
}

private final class MockAdNetworkUnit: NSObject, AdNetworkUnit {
    var uid: String
    var demandId: String
    var label: String
    var pricefloor: Price
    var bidType: AdBidType = .cpm
    var extras: [String: BidonDecodable] = [:]
    var extrasJsonString: String?

    init(demandId: String, pricefloor: Price) {
        self.uid = demandId
        self.demandId = demandId
        self.label = demandId
        self.pricefloor = pricefloor
    }
}

/// Minimal Bid-conforming wrapper for BidContainer init
private final class DummyAnyBid: NSObject, Bid {
    typealias ProviderType = DemandProviderMock
    typealias DemandAdType = DemandAdMock

    let id: String
    let impressionId: String = ""
    let adType: AdType = .interstitial
    let adUnit: AnyAdUnit
    let price: Price
    let ad: DemandAdMock = DemandAdMock()
    let provider: DemandProviderMock = DemandProviderMock()
    let roundPricefloor: Price = 0
    let auctionConfiguration: AuctionConfiguration

    init(demandId: String, price: Price) {
        self.id = demandId
        self.price = price

        let adUnitModel = try! JSONDecoder().decode(AdUnitModel.self, from: """
        {"uid":"\(demandId)","demandId":"\(demandId)","bidType":"CPM","label":"\(demandId)","pricefloor":\(price),"ext":{},"timeout":10000}
        """.data(using: .utf8)!)
        self.adUnit = adUnitModel

        self.auctionConfiguration = AuctionConfiguration(
            auctionId: "",
            auctionConfigurationUid: "",
            auctionConfigurationId: 0,
            adUnits: [],
            segment: nil,
            token: nil,
            pricefloor: 0,
            auctionTimeout: 30000,
            tokens: [],
            isExternalNotificationsEnabled: false
        )
    }
}
