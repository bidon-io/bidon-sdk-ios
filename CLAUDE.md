# CLAUDE.md — Bidon SDK iOS

## Project Overview

Bidon is an open-source ad mediation SDK for iOS that provides publishers with transparent control over advertising auctions. It supports multiple demand partners (ad networks) through a modular adapter architecture, enabling fair in-app bidding and waterfall-based mediation.

- **Language:** Swift 5.0
- **Minimum iOS deployment target:** 14.0 (pods target 13.0)
- **Current SDK version:** defined in `Bidon/Shared/Constants.swift` (`Constants.sdkVersion`)
- **Workspace:** `BidOn.xcworkspace` (note the capitalization — capital O)
- **Package manager:** CocoaPods (no SPM support currently)
- **Jira project prefix:** `APDM-`

## Git Conventions — STRICT

### Branches

- **ALWAYS** name branches: `feature/APDM-{task_number}-short-description` or `bugfix/APDM-{task_number}-short-description`
- **NEVER** use `claude/` prefix or any other branch naming pattern
- If branch push fails, report the actual error — do NOT silently change the branch name

Examples:
- `feature/APDM-1844-podspec-core-range`
- `bugfix/APDM-1787-banner-layout-fix`

### Commits

- **One commit per task**
- Commit message format: `APDM-{task_number}: Short description of the change`
- Do NOT add `Co-Authored-By` trailers

Example: `APDM-1844: Add core range for adapters in podspecs`

### Pull Requests

- **PR title:** `Feature/APDM-{task_number}: Short description` or `Bugfix/APDM-{task_number}: Short description`
- **Target branch:** `develop`
- **CHANGELOG.md must be updated in every PR** (CI will fail otherwise — see `check_changelog.yml`)
- PR body MUST include a Jira task link and a clear summary of changes

**PR body format:**
```
## Summary
<what was done and why, 1-3 sentences>

## Jira
[APDM-{number}](https://appodeal.atlassian.net/browse/APDM-{number})
```

**Example PR:**
- Title: `Feature/APDM-1679: Add Support for Price Floors in LevelPlay`
- Body:
```
## Summary
Add price floor configuration support to the LevelPlay mediation adapter.
This allows publishers to set minimum CPM thresholds for LevelPlay demand.

## Jira
[APDM-1679](https://appodeal.atlassian.net/browse/APDM-1679)
```

### CHANGELOG.md Format

Entries go under the top version heading (e.g., `# Develop` or `# Release x.x.x`). Each entry is a bullet with a Jira ticket reference and description.

**Entry format:**
```
- APDM-{number} Short description
```

**Categories** (use as sub-headings `##` when grouping, in this order):
1. `## New features` — user-facing new functionality
2. `## Fixes` — bug fixes
3. `## Network updates` — ad network SDK version bumps
4. `## Service updates` — analytics/service SDK version bumps

**Example:**
```markdown
# Develop

## New features
- APDM-1679 Add Support for Price Floors in LevelPlay
- APDM-1546 Networks update

## Fixes
- APDM-1787 Banners layout fix
- APDM-1663 APDAsyncOperation crash
```

When adding to CHANGELOG.md, append your entry to the appropriate existing category under the top heading, or create the category if it doesn't exist yet. Do NOT create a new version heading.

## Task Workflow

Follow this sequence for every task:

### 1. Create branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/APDM-{number}-short-description
```

### 2. Implement changes
- Make code changes
- Update `CHANGELOG.md` under the top heading with your entry

### 3. Lint
SwiftLint must pass with **zero warnings and zero errors**:
```bash
./lint
```
This runs `./Pods/SwiftLint/swiftlint`. If Pods are not installed, use `swiftlint lint` directly.

### 4. Run tests
```bash
# Core SDK tests
xcodebuild test \
  -workspace BidOn.xcworkspace \
  -scheme Tests-Swift \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.4'
```

### 5. Build affected module
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

### 6. Commit and push
```bash
git add <files>
git commit -m "APDM-{number}: Short description of the change"
git push -u origin feature/APDM-{number}-short-description
```

### 7. Create PR
- Title: `Feature/APDM-{number}: Short description`
- Target: `develop`
- Include Jira link and summary in body

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
│   ├── BidonAdapterMetaAudienceNetwork/
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
| `check_changelog.yml` | PR opened/sync | Verify CHANGELOG.md was updated |
| `build_core.yml` | Manual dispatch | Build core XCFramework, optionally upload to S3 |
| `build_adapter.yml` | Manual dispatch | Build single adapter XCFramework |
| `build_full_sdk.yml` | Manual dispatch | Build full SDK (core + all adapters) |
| `trunk_core.yml` | Manual dispatch | Publish core podspec to CocoaPods trunk |
| `trunk_adapters.yml` | Manual dispatch | Publish adapter podspecs to trunk |
| `pods-updater.yml` | Scheduled/manual | Auto-update third-party pod versions |
| `claude-fix-deprecations.yml` | Scheduled/manual | Auto-fix SDK deprecation warnings |

**PR CI checks that MUST pass:**
1. **SwiftLint** — zero warnings, zero errors
2. **Tests Core** — `Tests-Swift` scheme passes
3. **Check Changelog** — `CHANGELOG.md` has been modified (skipped for `chore/pod-*` branches)

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
- Adapter identifiers: lowercase strings (e.g., `"applovin"`, `"amazon"`)

### File Organization
- One primary type per file
- File headers: standard Xcode template with `Created by Bidon Team on <date>`
- Extensions on external types go in `Extensions/` directories
- Models go in `Models/` subdirectories within each adapter

### Adapter Directory Structure
```
BidonAdapter<Name>/
├── <Name>DemandSourceAdapter.swift   # Main adapter class
├── BidonAdapter<Name>.h              # Umbrella header
├── CHANGELOG.md                      # Adapter changelog
├── Models/                           # Codable parameter/token structs
├── Providers/                        # Demand provider implementations
└── Wrappers/                         # Native SDK delegate bridges
```

### ObjC Interop
- Public SDK classes are annotated with `@objc` and `@objc(<BDN-prefixed name>)` for ObjC compatibility
- Example: `@objc(BDNSdk) public final class BidonSdk: NSObject`

### Style
- Swift 5 with modern conventions
- Use `guard` and early returns
- Prefer `let` over `var`
- Use typealiases for complex protocol compositions (e.g., `DemandSourceAdapter = DirectInterstitialDemandSourceAdapter & DirectRewardedAdDemandSourceAdapter & DirectAdViewDemandSourceAdapter`)
- Enums for namespacing constants (e.g., `Constants.API`, `Constants.Timeout`)
- `@Injected` property wrapper for dependency injection
- `@Atomic` / `@BarrierAtomic` property wrappers for thread safety
- Access control: `public` for SDK API, `internal` for adapter internals, `private` for implementation details
- `private(set) public` for read-only public properties

### SwiftLint Rules
Configured in `.swiftlint.yml` with a minimal `only_rules` set:
- `colon`, `comma`, `trailing_comma`, `unused_closure_parameter`
- `redundant_void_return`, `closure_spacing`, `opening_brace`
- Excludes: `Pods/`, `Carthage/`, `build/`, `DerivedData/`, `fastlane/`

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
- SwiftLint runs via `./lint` which delegates to `./Pods/SwiftLint/swiftlint`
