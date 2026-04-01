//
//  AdCacheStorageTests.swift
//  Tests
//

import XCTest
@testable import Bidon

// MARK: - Mock Ad

private final class MockAdUnit: NSObject, AdNetworkUnit {
    var uid: String
    var demandId: String
    var label: String
    var pricefloor: Price
    var bidType: AdBidType
    var extras: [String: BidonDecodable] = [:]
    var extrasJsonString: String?

    init(demandId: String, pricefloor: Price = 0, bidType: AdBidType = .cpm) {
        self.uid = demandId
        self.demandId = demandId
        self.label = demandId
        self.pricefloor = pricefloor
        self.bidType = bidType
    }
}

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
        self.adUnit = MockAdUnit(demandId: demandId, pricefloor: price)
    }
}

private func ad(_ name: String, _ price: Double) -> MockAd {
    return MockAd(demandId: name, price: price)
}

// MARK: - CacheStorage Tests

final class CacheStorageTests: XCTestCase {

    // MARK: - Basic Insert

    func testEmptyCacheAcceptsFirstBid() {
        let cache = CacheStorage(capacity: 3, threshold: 80)
        XCTAssertTrue(cache.insert(ad("A", 10), sticky: true))
        XCTAssertEqual(cache.peek()?.price, 10)
    }

    func testStickyProtection_Capacity1() {
        let cache = CacheStorage(capacity: 1, threshold: 80)
        XCTAssertTrue(cache.insert(ad("A", 5), sticky: true))
        XCTAssertFalse(cache.insert(ad("B", 4), sticky: false))
        XCTAssertEqual(cache.peek()?.price, 5)
    }

    func testThresholdRejects() {
        let cache = CacheStorage(capacity: 3, threshold: 80)
        cache.insert(ad("A", 10), sticky: true) // maxPrice=10, bar=8
        XCTAssertTrue(cache.insert(ad("B", 9), sticky: false))  // 9 >= 8
        XCTAssertTrue(cache.insert(ad("C", 8), sticky: false))  // 8 >= 8
        XCTAssertFalse(cache.insert(ad("D", 7), sticky: false)) // 7 < 8
    }

    func testThreshold0_AcceptsAll() {
        let cache = CacheStorage(capacity: 3, threshold: 0)
        cache.insert(ad("A", 10), sticky: true) // bar=0
        XCTAssertTrue(cache.insert(ad("B", 1), sticky: false))
        XCTAssertTrue(cache.insert(ad("C", 0.01), sticky: false))
    }

    func testThreshold100_OnlyFirstAccepted() {
        let cache = CacheStorage(capacity: 3, threshold: 100)
        cache.insert(ad("A", 7), sticky: true) // bar=7
        XCTAssertFalse(cache.insert(ad("B", 6), sticky: false)) // 6 < 7
    }

    func testDuplicateDemandIdAndPrice_Replaces() {
        let cache = CacheStorage(capacity: 3, threshold: 0)
        cache.insert(ad("A", 10), sticky: true)
        cache.insert(ad("B", 5), sticky: false)
        // Same demandId "B" AND same price → replaces (refreshes ad object)
        XCTAssertTrue(cache.insert(ad("B", 5), sticky: false))
    }

    func testSameDemandId_DifferentPrice_NotDuplicate() {
        let cache = CacheStorage(capacity: 3, threshold: 0)
        cache.insert(ad("A", 10), sticky: true)
        cache.insert(ad("A", 8), sticky: false)
        // Same demandId but different price → both kept (not a duplicate)
        XCTAssertFalse(cache.isFull) // 2/3
    }

    func testIsFull() {
        let cache = CacheStorage(capacity: 2, threshold: 80)
        XCTAssertFalse(cache.isFull)
        cache.insert(ad("A", 10), sticky: true)
        XCTAssertFalse(cache.isFull)
        cache.insert(ad("B", 9), sticky: false)
        XCTAssertTrue(cache.isFull)
    }

    func testPopFirst_RemovesStickyAndResorts() {
        let cache = CacheStorage(capacity: 3, threshold: 50)
        cache.insert(ad("A", 10), sticky: true)
        cache.insert(ad("B", 8), sticky: false)
        cache.insert(ad("C", 9), sticky: false)

        let popped = cache.popFirst()
        XCTAssertEqual(popped?.price, 10) // sticky head
        XCTAssertEqual(cache.peek()?.price, 9) // resorted: C before B
    }

    func testNoEviction_CallerChecksIsFull() {
        // Spec: "Main заполняется один раз за аукцион. Caller проверяет !isFull перед insert"
        let cache = CacheStorage(capacity: 2, threshold: 50)
        cache.insert(ad("A", 10), sticky: true)
        cache.insert(ad("B", 8), sticky: false)
        XCTAssertTrue(cache.isFull)
        // Caller should check isFull before calling insert.
        // But if insert is called anyway, threshold will reject since no room logic.
    }
}

// MARK: - FallbackCacheStorage Tests

final class FallbackCacheStorageTests: XCTestCase {

    func testBasicInsert() {
        let fb = FallbackCacheStorage(capacity: 2)
        XCTAssertTrue(fb.insert(ad("A", 7)))
        XCTAssertTrue(fb.insert(ad("B", 5)))
        XCTAssertEqual(fb.peek()?.price, 7) // sorted desc
    }

    func testEviction_NewMoreExpensive() {
        let fb = FallbackCacheStorage(capacity: 2)
        fb.insert(ad("A", 3))
        fb.insert(ad("B", 2))
        XCTAssertTrue(fb.isFull)

        // $5 > cheapest $2 → evicts
        XCTAssertTrue(fb.insert(ad("C", 5)))
        XCTAssertEqual(fb.cheapestPrice, 3) // $2 evicted, now $3 is cheapest
    }

    func testEviction_NewCheaperOrEqual_Rejected() {
        let fb = FallbackCacheStorage(capacity: 2)
        fb.insert(ad("A", 5))
        fb.insert(ad("B", 3))

        XCTAssertFalse(fb.insert(ad("C", 3)))  // equal → rejected
        XCTAssertFalse(fb.insert(ad("D", 2)))  // cheaper → rejected
    }

    func testDisabled_Capacity0() {
        let fb = FallbackCacheStorage(capacity: 0)
        XCTAssertTrue(fb.isDisabled)
        XCTAssertTrue(fb.isFull)
        XCTAssertFalse(fb.insert(ad("A", 10)))
    }

    func testDuplicateDemandIdAndPrice_Replaces() {
        let fb = FallbackCacheStorage(capacity: 2)
        fb.insert(ad("A", 5))
        fb.insert(ad("B", 3))
        // Same demandId "B" AND same price → replaces
        XCTAssertTrue(fb.insert(ad("B", 3)))
        XCTAssertEqual(fb.cheapestPrice, 3)
    }

    func testSameDemandId_DifferentPrice_NotDuplicate() {
        let fb = FallbackCacheStorage(capacity: 3)
        fb.insert(ad("A", 5))
        fb.insert(ad("A", 3))
        // Same demandId but different price → both kept
        XCTAssertFalse(fb.isFull) // 2/3
    }
}

// MARK: - AdCacheStorage Tests (spec examples)

final class AdCacheStorageTests: XCTestCase {

    private func makeStorage(
        cacheSize: Int, threshold: Int, fallbackSize: Int
    ) -> AdCacheStorage {
        return AdCacheStorage(
            main: CacheStorage(capacity: cacheSize, threshold: threshold, tag: "test"),
            fallback: FallbackCacheStorage(capacity: fallbackSize, tag: "test")
        )
    }

    // MARK: - Spec §14.1: cacheSize=3, threshold=70, fallbackSize=2

    func testSpec_14_1() {
        let s = makeStorage(cacheSize: 3, threshold: 70, fallbackSize: 2)

        // $10 sticky → Main
        XCTAssertEqual(s.route(ad("net1", 10), sticky: true), .insertedMain)
        // mainBar = 10 * 0.7 = 7

        // $9 → Main (9 >= 7)
        XCTAssertEqual(s.route(ad("net2", 9), sticky: false), .insertedMain)
        // $8 → Main FULL (8 >= 7)
        XCTAssertEqual(s.route(ad("net3", 8), sticky: false), .insertedMain)
        XCTAssertTrue(s.main.isFull)

        // $7 → Main full → Fallback
        XCTAssertEqual(s.route(ad("net4", 7), sticky: false), .insertedFallback)
        // $5 → Main full → Fallback
        XCTAssertEqual(s.route(ad("net5", 5), sticky: false), .insertedFallback)
        XCTAssertTrue(s.fallback.isFull)

        // $3 → Main full, Fb full ($3 <= cheapest $5) → shouldStop
        XCTAssertTrue(s.shouldStop(ecpm: 3))

        // Verify contents
        XCTAssertEqual(s.main.peek()?.price, 10)
        XCTAssertEqual(s.fallback.peek()?.price, 7)
    }

    // MARK: - Spec §14.2: cacheSize=1, threshold=80, fallbackSize=3

    func testSpec_14_2() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 3)

        // $5 sticky → Main
        XCTAssertEqual(s.route(ad("net1", 5), sticky: true), .insertedMain)
        XCTAssertTrue(s.main.isFull) // capacity=1

        // $4, $3, $2 → Main full (sticky) → Fallback
        XCTAssertEqual(s.route(ad("net2", 4), sticky: false), .insertedFallback)
        XCTAssertEqual(s.route(ad("net3", 3), sticky: false), .insertedFallback)
        XCTAssertEqual(s.route(ad("net4", 2), sticky: false), .insertedFallback)
        XCTAssertTrue(s.fallback.isFull)
    }

    // MARK: - Spec §14.3: show() cancels, cache preserved

    func testSpec_14_3_CachePreservedAfterPop() {
        let s = makeStorage(cacheSize: 3, threshold: 70, fallbackSize: 2)

        s.route(ad("net1", 8), sticky: true)
        s.route(ad("net2", 7), sticky: false)
        s.route(ad("net3", 6), sticky: false)

        // show() → pop $8
        let shown = s.popFirst()
        XCTAssertEqual(shown?.price, 8)

        // Main: [$7, $6] — still available
        XCTAssertEqual(s.peekMain()?.price, 7)
    }

    // MARK: - Spec §14.4: Main not full (threshold cuts)

    func testSpec_14_4() {
        let s = makeStorage(cacheSize: 3, threshold: 80, fallbackSize: 2)

        // $10 sticky → Main
        s.route(ad("net1", 10), sticky: true)
        // mainBar = 10 * 0.8 = 8

        // $7 < $8 → rejected by Main → Fallback
        XCTAssertEqual(s.route(ad("net2", 7), sticky: false), .insertedFallback)
        // $5 → Fallback
        XCTAssertEqual(s.route(ad("net3", 5), sticky: false), .insertedFallback)
        XCTAssertTrue(s.fallback.isFull)

        // $3 → Main reject (threshold), Fb full ($3 <= $5) → STOP
        XCTAssertTrue(s.shouldStop(ecpm: 3))

        // Main only 1/3
        XCTAssertFalse(s.main.isFull)
        XCTAssertEqual(s.main.peek()?.price, 10)
    }

    // MARK: - Spec §14.5: Repeated auction updates Fallback

    func testSpec_14_5() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)

        // Auction 1
        s.route(ad("net1", 5), sticky: true)
        s.route(ad("net2", 3), sticky: false) // → Fallback
        s.route(ad("net3", 2), sticky: false) // → Fallback FULL

        // show → pop $5
        s.popFirst()
        // Fb pop $3, Fb pop $2 (simulating show cycles via auction→no-fill→fallback)
        s.fallback.popFirst()
        s.fallback.popFirst()

        // Auction 2: fresh fills
        s.route(ad("net4", 6), sticky: true) // Main
        s.route(ad("net5", 4), sticky: false) // → Fallback
        s.route(ad("net6", 3.5), sticky: false) // → Fallback FULL

        XCTAssertEqual(s.main.peek()?.price, 6)
        XCTAssertEqual(s.fallback.peek()?.price, 4)
    }

    // MARK: - Spec §14.6: Fallback eviction from stale bids

    func testSpec_14_6() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)

        // Auction 1: $5 → Main, $2,$1 → Fallback
        s.route(ad("net1", 5), sticky: true)
        s.route(ad("net2", 2), sticky: false)
        s.route(ad("net3", 1), sticky: false)

        // show $5, Main empty. Fallback [$2, $1] NOT touched.
        s.popFirst()

        // Auction 2: $10 → Main, $5 → Fb evicts $1, $4 → Fb evicts $2
        s.route(ad("net4", 10), sticky: true)
        // mainBar = 10*0.8 = 8. $5 < $8 → Main reject → Fallback
        XCTAssertEqual(s.route(ad("net5", 5), sticky: false), .insertedFallback)
        // Fb was [$2,$1], $5 > $1 → evicts $1. Fb: [$5,$2]
        XCTAssertEqual(s.fallback.cheapestPrice, 2)

        XCTAssertEqual(s.route(ad("net6", 4), sticky: false), .insertedFallback)
        // $4 > $2 → evicts $2. Fb: [$5,$4]
        XCTAssertEqual(s.fallback.cheapestPrice, 4)
        XCTAssertEqual(s.fallback.peek()?.price, 5)
    }

    // MARK: - Spec §14.7: cacheSize=1, fallbackSize=0

    func testSpec_14_7() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 0)

        s.route(ad("net1", 5), sticky: true)
        XCTAssertTrue(s.main.isFull)
        XCTAssertTrue(s.fallback.isDisabled)

        // Next: Main full + Fb disabled → STOP immediately
        XCTAssertTrue(s.shouldStop(ecpm: 3))
        XCTAssertTrue(s.shouldStop(ecpm: 10)) // even expensive can't go anywhere
    }

    // MARK: - Spec §14.8: threshold=0

    func testSpec_14_8() {
        let s = makeStorage(cacheSize: 3, threshold: 0, fallbackSize: 0)

        s.route(ad("net1", 10), sticky: true)  // bar=0
        XCTAssertEqual(s.route(ad("net2", 1), sticky: false), .insertedMain)
        XCTAssertEqual(s.route(ad("net3", 0.01), sticky: false), .insertedMain)
        XCTAssertTrue(s.main.isFull)

        // Full + disabled → STOP
        XCTAssertTrue(s.shouldStop(ecpm: 0.001))
    }

    // MARK: - shouldStop pre-filter

    func testShouldStop_MainNotFull_AboveThreshold() {
        let s = makeStorage(cacheSize: 3, threshold: 80, fallbackSize: 0)
        s.route(ad("A", 10), sticky: true) // bar=8
        // Main 1/3, ecpm=9 >= bar=8 → can accept Main
        XCTAssertFalse(s.shouldStop(ecpm: 9))
    }

    func testShouldStop_MainNotFull_BelowThreshold_FallbackHasRoom() {
        let s = makeStorage(cacheSize: 3, threshold: 80, fallbackSize: 2)
        s.route(ad("A", 10), sticky: true) // bar=8
        // ecpm=5 < bar=8 → can't accept Main. Fb empty → can accept Fb
        XCTAssertFalse(s.shouldStop(ecpm: 5))
    }

    func testShouldStop_MainFull_FallbackCanEvict() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)
        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 3), sticky: false) // → Fb
        s.route(ad("C", 2), sticky: false) // → Fb FULL. cheapest=2

        // ecpm=5 → can't accept Main (full), but Fb: $5 > cheapest $2 → can evict
        XCTAssertFalse(s.shouldStop(ecpm: 5))

        // ecpm=2 → can't Main, Fb: $2 <= cheapest $2 → STOP
        XCTAssertTrue(s.shouldStop(ecpm: 2))
    }

    func testShouldStop_EmptyCache_NeverStops() {
        let s = makeStorage(cacheSize: 3, threshold: 80, fallbackSize: 0)
        // No bids yet → thresholdBar = nil → never stop
        XCTAssertFalse(s.shouldStop(ecpm: 0.01))
    }

    // MARK: - Route rejected when both can't accept

    func testRoute_BothReject() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 0)
        s.route(ad("A", 5), sticky: true)

        // Main full+sticky, Fb disabled → rejected
        XCTAssertEqual(s.route(ad("B", 4), sticky: false), .rejected)
    }

    // MARK: - Pop order: Main first, then Fallback

    func testPopFirst_MainThenFallback() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)
        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 5), sticky: false) // → Fb
        s.route(ad("C", 3), sticky: false) // → Fb

        XCTAssertEqual(s.popFirst()?.price, 10) // Main
        XCTAssertEqual(s.popFirst()?.price, 5)  // Fallback best
        XCTAssertEqual(s.popFirst()?.price, 3)  // Fallback last
        XCTAssertNil(s.popFirst())               // empty
    }
}

// MARK: - Flow Tests (spec §5–§8, §15)

/// Tests simulating full loadAd/show flows as described in the spec.
/// These operate on AdCacheStorage since it holds all cache state.
final class AdCacheFlowTests: XCTestCase {

    private func makeStorage(
        cacheSize: Int, threshold: Int, fallbackSize: Int
    ) -> AdCacheStorage {
        return AdCacheStorage(
            main: CacheStorage(capacity: cacheSize, threshold: threshold, tag: "flow"),
            fallback: FallbackCacheStorage(capacity: fallbackSize, tag: "flow")
        )
    }

    // MARK: - §5: Pricefloor not checked on peek/pop

    func testSpec5_PricefloorNotCheckedOnPeek() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 1)

        // Fill cache with cheap ad
        s.route(ad("A", 0.50), sticky: true)

        // peek returns ad even though price is very low
        // (spec: pricefloor not checked — caller's responsibility)
        XCTAssertNotNil(s.peekMain())
        XCTAssertEqual(s.peekMain()?.price, 0.50)
    }

    func testSpec5_PricefloorNotCheckedOnPop() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 0)

        s.route(ad("A", 0.01), sticky: true)

        // pop returns ad regardless of how cheap it is
        let popped = s.popFirst()
        XCTAssertNotNil(popped)
        XCTAssertEqual(popped?.price, 0.01)
    }

    // MARK: - §6: State Machine

    /// §6: loadAd at .ready → instant from Main (bypass state)
    func testSpec6_LoadAdWhenReady_InstantFromMain() {
        let s = makeStorage(cacheSize: 3, threshold: 70, fallbackSize: 2)

        // Simulate auction filled cache
        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 9), sticky: false)
        s.route(ad("C", 8), sticky: false)

        // "loadAd" → Main.peek() != nil → instant serve
        XCTAssertNotNil(s.peekMain())
        XCTAssertEqual(s.peekMain()?.price, 10)

        // Second loadAd → still returns from cache (peek doesn't remove)
        XCTAssertNotNil(s.peekMain())
        XCTAssertEqual(s.peekMain()?.price, 10)
    }

    /// §6: .idle → .auction when Main empty (Fallback may have items)
    func testSpec6_AuctionOnlyWhenMainEmpty() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)

        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 3), sticky: false) // → Fallback

        // Main has ad → no auction needed
        XCTAssertNotNil(s.peekMain())

        // Pop Main
        s.popFirst()

        // Main empty, but Fallback has [$3]
        XCTAssertNil(s.peekMain())
        XCTAssertNotNil(s.peekFallback())
        // → state should go to .auction (Main empty), Fallback used only as no-fill backup
    }

    // MARK: - §7: loadAd flow

    /// §7 step 1: Main.peek != null → instant didLoad
    func testSpec7_Step1_MainNotEmpty_InstantServe() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 1)

        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 9), sticky: false)

        // loadAd → Main.peek → $10 → didLoad (no auction)
        let cached = s.peekMain()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.price, 10)
    }

    /// §7 step 4: auction fills → first bid = didLoad, rest cached
    func testSpec7_Step4_AuctionFills() {
        let s = makeStorage(cacheSize: 3, threshold: 70, fallbackSize: 2)
        var isFirstFill = true

        // Simulate waterfall: $10, $9, $8, $7, $5
        let waterfall: [(String, Double)] = [("A", 10), ("B", 9), ("C", 8), ("D", 7), ("E", 5)]
        var didLoadAd: Ad?
        var cachedAds: [Ad] = []

        for (name, price) in waterfall {
            if s.shouldStop(ecpm: price) { break }

            let bid = ad(name, price)
            let result = s.route(bid, sticky: isFirstFill)

            if result != .rejected {
                if isFirstFill {
                    didLoadAd = bid // WIN → didLoad
                } else {
                    cachedAds.append(bid) // CACHE
                }
            }

            isFirstFill = false
        }

        // First bid delivered
        XCTAssertEqual(didLoadAd?.price, 10)

        // Rest cached: $9, $8 in Main, $7, $5 in Fallback
        XCTAssertEqual(cachedAds.count, 4)
        XCTAssertTrue(s.main.isFull)
        XCTAssertTrue(s.fallback.isFull)
    }

    /// §7 step 4: auction no-fill → Fallback.peek → didLoad
    func testSpec7_Step4_NoFill_FallbackSaves() {
        let s = makeStorage(cacheSize: 2, threshold: 70, fallbackSize: 2)

        // Previous auction filled Fallback
        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 2), sticky: false) // → Fallback (threshold reject)

        // show → pop $5
        s.popFirst()
        XCTAssertNil(s.peekMain())

        // New auction: simulated no-fill (no bids)
        // → check Fallback
        let fallbackAd = s.peekFallback()
        XCTAssertNotNil(fallbackAd)
        XCTAssertEqual(fallbackAd?.price, 2) // saved by Fallback
    }

    /// §7 step 4: auction no-fill → Fallback empty → didFailToLoad
    func testSpec7_Step4_NoFill_NoFallback() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 0)

        s.route(ad("A", 5), sticky: true)

        // show → pop
        s.popFirst()

        // New auction: no-fill
        XCTAssertNil(s.peekMain())
        XCTAssertNil(s.peekFallback()) // Fallback disabled → didFailToLoad
    }

    /// §7 step 3: request failure → Fallback.peek → didLoad
    func testSpec7_Step3_RequestFailure_FallbackSaves() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)

        // Fill from previous auction
        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 3), sticky: false) // → Fb
        s.route(ad("C", 2), sticky: false) // → Fb

        // show → pop $5
        s.popFirst()

        // Auction request fails (network error) → check Fallback
        let fallbackAd = s.peekFallback()
        XCTAssertNotNil(fallbackAd)
        XCTAssertEqual(fallbackAd?.price, 3)
    }

    // MARK: - §8: show()

    /// §8: show → popFirst(Main ?? Fallback) → cancel auction
    func testSpec8_Show_PopFromMainFirst() {
        let s = makeStorage(cacheSize: 2, threshold: 70, fallbackSize: 2)

        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 9), sticky: false)
        s.route(ad("C", 5), sticky: false) // → Fb
        s.route(ad("D", 3), sticky: false) // → Fb

        // show → Main.popFirst
        let shown = s.popFirst()
        XCTAssertEqual(shown?.price, 10)

        // Remaining: Main [$9], Fb [$5, $3]
        XCTAssertEqual(s.peekMain()?.price, 9)
        XCTAssertEqual(s.peekFallback()?.price, 5)
    }

    /// §8: show exhausts Main → next pop from Fallback
    func testSpec8_Show_FallsBackToFallback() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 2)

        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 3), sticky: false) // → Fb
        s.route(ad("C", 2), sticky: false) // → Fb

        // Pop Main
        XCTAssertEqual(s.popFirst()?.price, 5)
        XCTAssertNil(s.peekMain())

        // Pop from Fallback
        XCTAssertEqual(s.popFirst()?.price, 3)
        XCTAssertEqual(s.popFirst()?.price, 2)
        XCTAssertNil(s.popFirst())
    }

    // MARK: - §15 Кейс 1: Два последовательных loadAd

    /// §15.1 Scenario B: 2nd load after auction, without show → instant from cache
    func testSpec15_1B_SecondLoadWithoutShow_InstantFromCache() {
        let s = makeStorage(cacheSize: 2, threshold: 70, fallbackSize: 1)

        // First load → auction fills cache
        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 3), sticky: false)

        // Second loadAd → Main.peek → $5 → instant
        XCTAssertEqual(s.peekMain()?.price, 5)

        // peek doesn't remove — same bid returned
        XCTAssertEqual(s.peekMain()?.price, 5)
    }

    /// §15.1 Scenario C: load → show → load (cache not empty)
    func testSpec15_1C_LoadShowLoad_CacheNotEmpty() {
        let s = makeStorage(cacheSize: 2, threshold: 70, fallbackSize: 1)

        s.route(ad("A", 5), sticky: true)
        s.route(ad("B", 4), sticky: false) // 4 >= 3.50 (70% of 5) → Main

        // show → pop $5
        s.popFirst()

        // loadAd → Main.peek → $4 → instant (no auction)
        XCTAssertEqual(s.peekMain()?.price, 4)
    }

    /// §15.1 Scenario D: load → show → load (cache empty)
    func testSpec15_1D_LoadShowLoad_CacheEmpty() {
        let s = makeStorage(cacheSize: 1, threshold: 80, fallbackSize: 0)

        s.route(ad("A", 5), sticky: true)

        // show → pop $5
        s.popFirst()

        // loadAd → Main.peek == nil → need new auction
        XCTAssertNil(s.peekMain())
        XCTAssertTrue(s.main.isEmpty)
    }

    // MARK: - §15 Кейс 2: Fallback спасает no-fill

    func testSpec15_2_FallbackSavesNoFill() {
        let s = makeStorage(cacheSize: 2, threshold: 70, fallbackSize: 2)

        // Waterfall: $5, $2
        s.route(ad("A", 5), sticky: true)
        // $2 < threshold ($3.50) → Fallback
        s.route(ad("B", 2), sticky: false)

        XCTAssertEqual(s.peekMain()?.price, 5)
        XCTAssertEqual(s.peekFallback()?.price, 2)

        // show $5
        s.popFirst()

        // New auction → no-fill → Fallback saves
        XCTAssertNil(s.peekMain())
        XCTAssertEqual(s.peekFallback()?.price, 2) // rescued
    }

    // MARK: - Full lifecycle: multiple auction rounds

    /// Simulates full lifecycle: auction → show → auction → show → ...
    func testFullLifecycle_MultipleRounds() {
        let s = makeStorage(cacheSize: 2, threshold: 80, fallbackSize: 1)

        // === Round 1 ===
        // Waterfall: $10, $9, $7, $5
        s.route(ad("A", 10), sticky: true)
        s.route(ad("B", 9), sticky: false)
        // $7 < $8 (threshold) → Fallback
        s.route(ad("C", 7), sticky: false)
        // $5: shouldStop? Fb full, $5 <= $7 → no eviction → STOP
        XCTAssertTrue(s.shouldStop(ecpm: 5))

        // Main: [$10*, $9], Fallback: [$7]
        XCTAssertEqual(s.peekMain()?.price, 10)

        // load→$10 (instant). show→pop.
        s.popFirst()
        XCTAssertEqual(s.peekMain()?.price, 9)

        // load→$9 (instant). show→pop.
        s.popFirst()
        XCTAssertNil(s.peekMain())

        // load→Main empty→auction→no-fill→Fallback $7
        XCTAssertEqual(s.peekFallback()?.price, 7)

        // show→Fb pop $7
        s.popFirst()
        XCTAssertNil(s.peekFallback())

        // === Round 2 ===
        // Both empty → new auction
        XCTAssertTrue(s.main.isEmpty)
        XCTAssertTrue(s.fallback.isEmpty)

        s.route(ad("D", 12), sticky: true)
        s.route(ad("E", 11), sticky: false)
        s.route(ad("F", 8), sticky: false) // → Fb

        XCTAssertEqual(s.peekMain()?.price, 12)
        XCTAssertEqual(s.peekFallback()?.price, 8)
    }
}
