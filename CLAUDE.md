# CLAUDE.md — Bidon SDK iOS

## Project Overview

Bidon is an open-source ad mediation SDK for iOS that provides publishers with transparent control over advertising auctions. It supports multiple demand partners (ad networks) through a modular adapter architecture, enabling fair in-app bidding and waterfall-based mediation.

- **Language:** Swift 5.0
- **Minimum iOS deployment target:** 14.0 (pods target 13.0)
- **Current SDK version:** defined in `Bidon/Shared/Constants.swift` (`Constants.sdkVersion`)
- **Workspace:** `BidOn.xcworkspace` (note the capitalization)
- **Package manager:** CocoaPods (no SPM support currently)

## Repository Structure

```
├── Bidon/                          # Core SDK framework
│   ├── SDK/                        # Public API (BidonSdk, ad types, delegates)
│   ├── Modules/                    # Internal modules
│   │   ├── Adapters/               # Adapter protocols and registration
│   │   ├── Auction/                # Auction engine (controllers, builders, comparators)
│   │   ├── Environment/            # Device, app, user, geo, session info
│   │   └── Observer/               # Mediation and revenue observation
│   ├── Mediation/                  # Ad loading, bid management, impressions
│   ├── Networking/                 # HTTP client, request/response models
│   └── Shared/                     # Constants, extensions, logging, utilities
│
├── Adapters/                       # First-party demand source adapters
│   ├── Adapters.xcodeproj
│   ├── BidonAdapterAppLovin/
│   ├── BidonAdapterBidMachine/
│   ├── BidonAdapterGoogleMobileAds/
│   ├── BidonAdapterGoogleAdManager/
│   ├── BidonAdapterMeta*/
│   ├── BidonAdapterUnityAds/
│   ├── BidonAdapterMintegral/
│   ├── BidonAdapterVungle/
│   ├── BidonAdapterInMobi/
│   ├── BidonAdapterAmazon/
│   ├── BidonAdapterBigoAds/
│   ├── BidonAdapterDTExchange/
│   ├── BidonAdapterMobileFuse/
│   ├── BidonAdapterMoloco/
│   ├── BidonAdapterChartboost/
│   ├── BidonAdapterIronSource/
│   ├── BidonAdapterMyTarget/
│   ├── BidonAdapterYandex/
│   ├── BidonAdapterStartIo/
│   ├── BidonAdapterTaurusX/
│   └── BidonAdapterZmaticoo/
│
├── ThirdPartyMediationAdapters/    # Adapters for 3rd-party mediators using Bidon
│   ├── AppLovinMediationBidonAdapter/
│   └── ISBidonCustomAdapter/
│
├── Tests/                          # Unit tests
│   ├── Tests-Swift/                # Core SDK tests (auction, extensions, mocks)
│   ├── AdaptersTests/              # Per-adapter tests
│   └── Tests.xcodeproj
│
├── Sandbox/                        # Demo app for development/testing
│
├── fastlane/                       # Build, release, and podspec automation
│   ├── Fastfile                    # Lanes: core, adapters, trunk publishing
│   └── actions/                    # Custom Fastlane actions
│
├── scripts/                        # Shell scripts
│   ├── build_adapter.sh
│   └── scan_deprecations.sh
│
├── .github/
│   ├── workflows/                  # CI/CD (see CI section below)
│   └── scripts/                    # Ruby scripts for CI automation
│
├── Podfile                         # CocoaPods dependency definitions
├── Gemfile                         # Ruby dependencies (cocoapods, fastlane, etc.)
└── .swiftlint.yml                  # SwiftLint configuration
```

## Build & Development

### Prerequisites
- Xcode 16.2+
- Ruby (for CocoaPods and Fastlane)
- CocoaPods (`gem install cocoapods`)

### Setup
```bash
bundle install          # Install Ruby gems
pod install             # Install CocoaPods dependencies
open BidOn.xcworkspace  # Open in Xcode (use workspace, NOT project)
```

### Building
```bash
# Build core SDK
xcodebuild build \
  -workspace BidOn.xcworkspace \
  -scheme Bidon \
  -destination 'generic/platform=iOS Simulator'

# Build a specific adapter
xcodebuild build \
  -workspace BidOn.xcworkspace \
  -scheme BidonAdapterAppLovin \
  -destination 'generic/platform=iOS Simulator'
```

### Running Tests
```bash
# Core SDK tests
xcodebuild test \
  -workspace BidOn.xcworkspace \
  -scheme Tests-Swift \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.4'
```

### Linting
```bash
swiftlint lint
```

SwiftLint is configured with a minimal rule set (`.swiftlint.yml`):
- `colon`, `comma`, `trailing_comma`, `unused_closure_parameter`
- `redundant_void_return`, `closure_spacing`, `opening_brace`
- Excludes: `Pods/`, `Carthage/`, `build/`, `DerivedData/`, `fastlane/`

### Fastlane
Key lanes (run from project root via `bundle exec fastlane <lane>`):
- `core` — Build core SDK XCFramework
- `adapter` — Build a single adapter XCFramework
- `adapters` — Build all adapter XCFrameworks
- `trunk_core` / `trunk_adapter` / `trunk_adapters` — Publish to CocoaPods trunk

## CI/CD (GitHub Actions)

| Workflow | Trigger | Purpose |
|---|---|---|
| `tests_core.yml` | PR opened/sync | Run `Tests-Swift` scheme on iOS Simulator |
| `swiftlint.yml` | PR opened/sync | Lint all Swift code |
| `build_core.yml` | Manual dispatch | Build core XCFramework, optionally upload to S3 |
| `build_adapter.yml` | Manual dispatch | Build single adapter XCFramework |
| `build_full_sdk.yml` | Manual dispatch | Build full SDK (core + all adapters) |
| `trunk_core.yml` | Manual dispatch | Publish core podspec to CocoaPods trunk |
| `trunk_adapters.yml` | Manual dispatch | Publish adapter podspecs to trunk |
| `pods-updater.yml` | Scheduled/manual | Auto-update third-party pod versions |
| `claude-fix-deprecations.yml` | Scheduled/manual | Auto-fix SDK deprecation warnings |

## Architecture & Key Concepts

### Adapter Pattern
Each ad network integration follows a consistent pattern:

1. **Adapter class** (`*DemandSourceAdapter`) — Entry point conforming to `Adapter` protocol
   - Has a static `identifier` string (e.g., `"applovin"`)
   - Properties: `demandId`, `name`, `adapterVersion`, `sdkVersion`
   - Conforms to one or more `DemandSourceAdapter` protocols (Direct/Bidding x Interstitial/Rewarded/AdView)
   - Factory methods return demand providers

2. **Demand Providers** — Handle ad loading for specific ad types
   - `DirectDemandProvider` — Waterfall-based (loads with price floors)
   - `BiddingDemandProvider` — Real-time bidding (returns tokens, processes bids)

3. **Initialization** — Adapters conform to `InitializableAdapter` or `ParameterizedInitializableAdapter`

4. **Models** — Per-adapter parameter models (Codable structs)

5. **Wrappers/Providers** — Bridge between Bidon protocols and native SDK delegates

### Ad Types
- **Interstitial** — Full-screen ads
- **Rewarded** — Full-screen ads with rewards
- **AdView (Banner)** — View-based display ads

### Dependency Injection
The SDK uses a custom `@Injected` property wrapper for dependency injection (see `Bidon/Shared/PropertyWrappers/`).

### Networking
Custom HTTP client in `Bidon/Networking/` with request builders and JSON codable models.

### Auction Engine
Located in `Bidon/Modules/Auction/` — Handles concurrent auction rounds, bid comparison, winner election, and demand source orchestration.

## Code Conventions

### Naming
- Adapter modules: `BidonAdapter<NetworkName>` (e.g., `BidonAdapterAppLovin`)
- Adapter classes: `<NetworkName>DemandSourceAdapter`
- Demand providers: `<NetworkName><AdType>DemandProvider`
- Test targets: mirror source structure with `Tests` suffix

### File Organization
- One primary type per file
- File headers: standard Xcode template with `Created by Bidon Team on <date>`
- Extensions on external types go in `Extensions/` directories
- Models go in `Models/` subdirectories within each adapter

### ObjC Interop
- Public SDK classes are annotated with `@objc` and `@objc(<BDN-prefixed name>)` for ObjC compatibility
- Example: `@objc(BDNSdk) public final class BidonSdk: NSObject`

### Style
- Swift 5 with modern conventions
- Use `guard` and early returns
- Prefer `let` over `var`
- Use typealiases for complex protocol compositions
- Enums for namespacing constants (e.g., `Constants.API`, `Constants.Timeout`)

### Commit Messages
Follow conventional commits format:
- `chore(pods): <dependency> <old_version> -> <new_version>` — Dependency updates
- `Feature/<description>` or `fix <description>` — Feature/fix PRs
- Reference ticket IDs where applicable: `BDN-XXXX`

## Adding a New Adapter

1. Create directory `Adapters/BidonAdapter<Name>/` with:
   - `<Name>DemandSourceAdapter.swift` — Main adapter class
   - `BidonAdapter<Name>.h` — Umbrella header
   - `Models/` — Parameter structs
   - `Providers/` or `Wrappers/` — Demand provider implementations
   - `CHANGELOG.md` — Adapter changelog

2. Add the CocoaPods dependency in `Podfile` (as a function and target)

3. Register the adapter class in `Bidon/Shared/Constants.swift` → `Constants.Adapters.classes`

4. Add a test target in `Tests/AdaptersTests/BidonAdapter<Name>Tests/`

5. Add the target to `Adapters/Adapters.xcodeproj`

6. Add the adapter to `$targets` and `$adapter_primary_pod` in `fastlane/Fastfile`

## Troubleshooting

- Always open `BidOn.xcworkspace`, not individual `.xcodeproj` files
- Run `pod install` after pulling changes that modify `Podfile`
- If builds fail with missing modules, clean DerivedData and rebuild
- The workspace name is `BidOn.xcworkspace` (capital O), not `Bidon.xcworkspace`
