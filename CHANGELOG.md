# Develop

- CI: skip CI Adapter Quality re-run when latest push only modifies Podfile.lock (merge-conflict fixes on `chore/pod-*` PRs)

## Fixes
- APDM-2195 Fix SIGABRT in AdaptersInitializator when adapter init main-queue dispatch races the timeout watchdog
- APDM-2195 Fix banner crash from BannerAdManager.state data race between auction completion and notifyLoss by serializing state access through an NSLock

# Release 0.15.0

- APDM-2420 BidMachine adapter: configurable `mediation_mode` via `BidMachineDemandSourceAdapter(mediationMode:)` initializer (defaults to "bidon")
- CI: load pod-to-adapter mapping from API, fix Claude Code secret name, remove stale local script
- BDN-1139 Viewability improvements
- BDN-1140 Fix demand adapter delegates - banner adapters no longer call fullscreen delegate callbacks
- BDN-1150 Migrated workflows to new podspec push flow
- BDN-1155 Added SPM support for Bidon Core
- BDN-1147 Add callback logging to Sandbox demo screens for ad lifecycle events
- BDN-1114 Concurrent auction controller refactoring
- BDN-1177 Dependamachine migration

# Release 0.14.0

## Fixes
- BDN-1127 Setup core range for adapters in podspec
- BDN-1123 Visibility tracker
- BDN-1033 Device info
- BDN-1105 Code clean
- BDN-1111 CI Deprecation job

# Release 0.13.0

## New features
- BDN-1070 Added Yandex Bidding support
- BND-1046 Networks update
- BDN-1631 Podspec generation - update
- BDN-1083 CI S3 zip-archive checking
- BDN-1013 Pods updater bot 
- BDN-1673 Podspecs generation logic - update
- BDN-1672 Github Actions flow - Slack info
- BDN-1107 Podspecs new source

## Fixes
- BDN-1092 Crashes - Start.io
- BDN-1096 Fixed crash in ConcurrentAuctionController

# Release 0.12.0

## New features
- BDN-1076 Support bcat, badv, and bapps for BidMachine CPM ad units
- APDM-1631 Podspec generation - update
- BDN-1083 CI S3 zip-archive checking
- BDN-1067 Update Moloco
- BDN-1078 Added mediator and ad_unit_ids params support for Applovin adapter
- BDN-1069 Fixes in BCA banners
- BDN-1010 Adapter Versioning and Github Actions
- BDN-1017 TaurusX implementation
- BDN-1056 Start.io implementation

## Fixes
- BDN-1053 Location waiting fix
- BDN-1062 userAgent freeze in iOS 26 WebView fix

# Release 0.11.0

- BDN-1001 Migrate IronSource and LevelPlay API to new API

## New features
- BDN-1033 Bidon request params
- BDN-1009 Bidon init by order
- BDN-1031 Moloco RTB adapters - implemented
- BDN-1038 InMobi RTB adapters - implemented

## Fixes
- BDN-992 VK Ads debug mode support

# Release 0.10.0

## Network updates
- BDN-1040 YandexSDK updated to v7.15.1

## New features

- BDN-1025 Support External Win/Loss Notification for BCAMAX
- BDN-1023 Exclude BM SDK-Win/Loss Notification in RTB-mode
- BDN-1021 Fix Win/Loss Notification Logic Based on external_win_notifications
- BDN-1006 AdNetworks updated
- BDN-971 AdNetworks operators updated
- BDN-1474 Fixed adapters init
- BDN-1475 AppMetricaAnalytics version fix

## Fixes
- BDN-1007 CLGeocoder multiple processing - fix

# Release 0.9.0

## Fixes
- BDN-1007 CLGeocoder multiple processing - fix

## New features
- BDN-987 VungleSDK Banner API - updated
- BDN-1396 Update BCA MAX callbacks
- BDN-966 Updated Bidmachine to 3.3.0. Added BM placements logic
- BDN-1411 Update IronSource network

# Release 0.8.1

## New features
- BDN-976 Refactor Ad Loading Logic Based on SDK Initialization State
- BDN-979 GitHub Actions for CI-CD

# Release 0.8.0

## New features
- BDN-1305 BCALP Adapter to Bidon - Interstitial 
- BDN-978 Initialization failure state
- BDN-942 New Bidon SDK init logic
- BDN-975 GitHub Actions

## Fixes
- BDN-1357 SKAdNetworks duplication fix

## Network updates


