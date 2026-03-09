# CacheStrategy 2 — Runner-Up Bid Caching

## Problem

When a live auction fails (no fill), the SDK has nothing to show. This causes **lost revenue** and **poor user experience**. CacheStrategy 2 solves this by reusing losing bids from previous auctions as a fallback.

---

## Core Idea

After each successful auction, the **runner-up bids** (losers with valid ads) are stored in a cache. When the next auction fails, the best cached bid is served instead of a no-fill.

```
┌─────────────────────────────────────────────────────────┐
│                    AUCTION SUCCESS                      │
│                                                         │
│   Bid A $5.00 ──► WINNER ──► Show to user               │
│   Bid B $3.50 ─┐                                        │
│   Bid C $2.10 ─┼─► RUNNER-UPS ──► BidCacheStore        │
│   Bid D $1.80 ─┘                                        │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼ (next auction)
┌─────────────────────────────────────────────────────────┐
│                    AUCTION FAILURE                      │
│                                                         │
│   No fill ──► selectFallback() ──► Bid B $3.50 (cached) │
│                                          │              │
│                                          ▼              │
│                                    reserve() ──► Show   │
└─────────────────────────────────────────────────────────┘
```

---

## Architecture

### Layer Overview

```
┌──────────────────────────────────────────────────────────────┐
│  Ad Formats (BannerView / Interstitial)                      │
│  Strategy selection based on AdCacheConfig                   │
└────────────────────────────┬─────────────────────────────────┘
                             │ Strategy 2
┌────────────────────────────▼─────────────────────────────────┐
│  Ad Managers                                                 │
│  DBannerAdManager  │  DInterstitialAdManager                 │
│  Orchestrate auction + cache lifecycle                       │
└────────────┬───────────────┬─────────────────────────────────┘
             │               │
┌────────────▼──┐   ┌────────▼──────────────────────────────┐
│ DAuction      │   │  DCachePolicy                         │
│ Controller    │   │  BannerCachePolicy                    │
│               │   │  InterstitialCachePolicy              │
│ Runs parallel │   │  Selects which bids to cache/fallback │
│ bid requests  │   └───────────────┬───────────────────────┘
└───────────────┘                   │
                        ┌───────────▼───────────────────────┐
                        │  BidCacheStore                    │
                        │  Thread-safe cache with           │
                        │  reservation system               │
                        │                                   │
                        │  ┌───────────────────────┐        │
                        │  │ entries: [CacheKey:   │        │
                        │  │  [CachedBid]]         │        │
                        │  │ reserved: [EntryID:   │        │
                        │  │  Reservation]         │        │
                        │  └───────────────────────┘        │
                        └───────────────────────────────────┘
```

### Key Components

| Component | File | Responsibility |
|-----------|------|----------------|
| `BidCacheStore` | `Cache/BidCacheStore.swift` | Thread-safe storage, reservation, TTL management |
| `CachedBid` | `Cache/CachedBid.swift` | Bid snapshot with TTL metadata + lazy builders |
| `DCachePolicy` | `Cache/DCachePolicy.swift` | Protocol: which bids to cache / which to use as fallback |
| `BannerCachePolicy` | `Formats/Banner/BannerCachePolicy.swift` | Banner-specific selection logic |
| `InterstitialCachePolicy` | `Formats/Fullscreen/InterstitialCachePolicy.swift` | Interstitial-specific selection logic |
| `DAuctionController` | `Controller/DAuctionController.swift` | Runs auction, bridges result to cache |
| `CacheImpressionDelegateProxy` | `Tools/CacheImpressionDelegateProxy.swift` | Manages confirm/release on impression lifecycle |
| `CacheStatsTracker` | `Tools/CacheStatsTracker.swift` | Hit/miss/savedFill statistics |

---

## Data Flow

### Happy Path (Auction Succeeds)

```
loadAd()
  └─► DAuctionController.runAuction()
        └─► [parallel bid requests]
              └─► Winner found
                    ├─► deliver winner to user
                    └─► cachePolicy.selectRunnerUps(allBids)
                              └─► BidCacheStore.replace(key, runnerUps)
```

### Fallback Path (Auction Fails)

```
loadAd()
  └─► DAuctionController.runAuction()
        └─► No fill
              └─► cachePolicy.selectFallbackCandidates(cache.peek(key))
                        └─► Best valid cached bid found
                              └─► BidCacheStore.reserve(entryID)
                                    └─► deliver cached bid to user
```

### Impression Lifecycle (Interstitial)

```
Reserved bid selected
  └─► CacheImpressionDelegateProxy tracks presentation
        ├─► willPresent()  ──► cache.confirm()  [remove permanently]
        ├─► didFailToPresent() ──► cache.release() [return to pool]
        └─► didHide() / didExpire() ──► cache.release() [return to pool]
```

---

## Cache Key & Partitioning

Each cache pool is keyed by:

```
CacheKey {
    adType:      .banner | .interstitial | .rewarded
    placementId: "default"
    segment:     "default"
}
```

Separate pools per ad type + placement + segment ensures no cross-contamination.

---

## Cache Policy Parameters

| Parameter | Banner | Interstitial |
|-----------|--------|--------------|
| Max runner-ups cached | 3 | 2 |
| Entry TTL | 8 min | 10 min |
| Min healthy TTL (merge) | 1 min | 1.5 min |
| Min TTL to show | 5 sec | 15 sec |
| Deduplication | 1 per demand ID | 1 per demand ID |
| Merge strategy | Higher price wins (unless entry unhealthy) | Same |

**Merge** happens when replacing the cache: existing entries with sufficient TTL and higher price may be kept alongside new runner-ups.

---

## Reservation System

Prevents the same cached bid from being shown twice:

```
BidCacheStore
├── entries   → available pool
└── reserved  → in-use bids (max 40s hold)

reserve(id)   → move entry from entries → reserved
confirm(id)   → delete from reserved (impression happened)
release(id)   → move from reserved → entries (can retry)
maintenance() → sweep expired entries and stale reservations
```

---

## CachedBid: Lazy Instantiation

Expensive ad objects are not created until the bid is actually used:

```swift
struct CachedBid {
    let payload: BidPayload      // DemandID, price, auctionID, adUnit
    let meta: Meta               // cachedAt, expiresAt, consentHash
    let makeAd: () -> Ad
    let makeImpressionController: () -> AnyObject
    let observeRevenue: (AdRevenueObserver) -> Void
}
```

Builders are invoked only when the cached bid is selected as fallback.

---

## Configuration (Server-Driven)

`AdCacheConfig` is fetched from the server at SDK init:

```swift
AdTypeCacheConfig {
    strategy:        Int   // 0=off, 1=Zhenya, 2=Dima
    adunitCacheSize: Int   // 1–10, default=1
    noFillDelayMs:   Int   // 2000–64000ms, default=2000
}
```

Strategy 2 is enabled per ad type independently (banner, interstitial, rewardedVideo).

---

## Privacy & Consent

Each `CachedBid.Meta` stores a `consentHash` at cache time.
`selectFallbackCandidates()` filters out bids whose consent hash differs from the current session — ensuring cached bids are never shown with mismatched consent state.

---

## Observability

`CacheStatsTracker` exposes:

| Metric | Description |
|--------|-------------|
| `hits` | Successful fallback serves |
| `misses` | Fallback attempted, cache empty/expired |
| `savedFills` | Total ads served from cache |
| `hitRate` | hits / (hits + misses) |
