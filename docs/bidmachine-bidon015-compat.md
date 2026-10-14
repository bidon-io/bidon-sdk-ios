# BidMachine adapter for Bidon 0.15.0

Candidate: `BidonAdapterBidMachine 3.8.0.4-bmplus.1`. Source branch: `chore/sdk-1338-bidon-015-compat`. Binary upload and podspec publication are separate steps and have not been performed.

## Source and scope

- Branch base: `93839f3deb0efc5ca00849d5c5a7dfef667d230a`, before SDK-748, with the adapter changelog at `3.8.0.2`.
- Backported behavior and tests: SDK-1338 from `50c042cf7f2d5388b3ad9515d16202b0a605e24f`.
- Server `custom_parameters.mediation_mode` wins; adapter mode is used only when the key is absent. All six bidding/direct providers share this behavior.
- SDK-748 (`DemandAdExtrasProvider`) is deliberately absent. Do not merge this compatibility branch as a replacement for the newer core SDK feature set.
- Compile against published **Bidon 0.15.0**, **BidMachine/Static 3.8.0**, and its published OMSDK dependency. Do not build the repository's core SDK and relabel it 0.15.0.
- The local podspec pins Bidon exactly to 0.15.0. The Dynamic subspec is retained for future packaging, but the verified Word Search consumer uses Static; dynamic linkage has not been tested.

## Local build

Requires Xcode 26, Ruby with `xcodeproj`, and a resolved Word Search export containing the published dependencies. The Ruby project generator checks the lock/manifest and exact dependency versions. Generated projects, binaries, podspec, and logs stay under ignored `build/bidmachine-bidon015`.

```bash
cd /Users/dzmitry/Work/Appodeal/bidon-sdk-ios
xcrun simctl list devices available
bash scripts/build_bidmachine_bidon015.sh \
  /Users/dzmitry/Work/Chardonnay/wordsearch/Builds/iOS-3.0.27-bmplus-beta5 \
  E6B48055-8A71-4EE3-8A82-9FE7B87E1316
```

Use an available simulator UDID on the machine. Ruby must load `xcodeproj`; the verified Ruby is `/Users/dzmitry/.rbenv/versions/3.1.7/bin/ruby`. The wrapper refuses to overwrite an existing candidate/test result: preserve or move the previous output directory first.

Outputs:

- `build/bidmachine-bidon015/BidonAdapterBidMachine-3.8.0.4-bmplus.1/BidonAdapterBidMachine.xcframework`
- Adjacent `BidonAdapterBidMachine.podspec.json`, intended for `:path` installation. Its prospective HTTP source is not published.
- `SDK1338-tests.xcresult`, build and test logs.
- `build-inputs.json` and, for the verified run, `binary-checks.json`.

The two Release slices are iphoneos arm64 and iphonesimulator arm64/x86_64. Debug simulator tests compile the same source against published Bidon 0.15.0, with no locally rebuilt Bidon core.

## Word Search link verification

Only in the generated export Podfile, replace the published adapter declaration with:

```ruby
pod 'BidonAdapterBidMachine', :path => '/Users/dzmitry/Work/Appodeal/bidon-sdk-ios/build/bidmachine-bidon015/BidonAdapterBidMachine-3.8.0.4-bmplus.1'
```

Run `pod install --no-repo-update`. Confirm the only resolved version changes are the adapter and its Static subspec; Bidon remains 0.15.0 and BidMachine remains 3.8.0.

```bash
xcodebuild build -workspace Unity-iPhone.xcworkspace -scheme Unity-iPhone \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /Users/dzmitry/Library/Developer/Xcode/DerivedData/Unity-iPhone-fakatrfcupfzptekvfqvuryhhnzk \
  -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

The explicit DerivedData path reuses the existing local build cache; select the corresponding location on another Mac. This is a native build/link check, not an archive, signing validation, upload, or runtime ad test.

Local override is **not persisted in Unity/AdsPackage**. Re-exporting Unity restores the published dependency from AdsPackage .11. Do not delete/move the candidate while the export Podfile points to it. To return to the published .3, restore its declaration and run pod install; the known linker incompatibility will return.

Original export Podfile, locks, pbxproj and Info.plist were preserved under `/private/tmp/wordsearch-bidon015-link-backup` before the local override. Do not overwrite unrelated later Xcode edits with the whole backup.

For release after approval: publish a versioned candidate and correct spec, update AdsPackage, publish the next package, update Word Search, re-export and validate the native build again. Neither existing 3.8.0.3 binaries nor published npm versions should be overwritten.

## Verified locally on 2026-10-14

- Release XCFramework built successfully for iphoneos arm64 and iphonesimulator arm64/x86_64.
- SDK-1338 Swift Testing suite: 7 tests passed against published Bidon 0.15.0. Full repository SwiftLint exited 0.
- Both adapter slices and the linked UnityFramework have no undefined references to `DemandAdExtrasProvider` or `additionalAdUnitExtras`.
- Word Search 3.0.27 Release native build exited 0 with `BUILD SUCCEEDED`, including linking UnityFramework and WordsSearch.app. Log: `/Users/dzmitry/Work/Chardonnay/wordsearch/Builds/wordsearch-bidon015-native-link.log`.
- Podfile.lock and Pods/Manifest.lock match. Only the adapter and its Static subspec changed from 3.8.0.3 to this local candidate; Bidon remains 0.15.0, BidMachine remains 3.8.0.
- Word Search tracked files remain unchanged. Existing automatic signing settings were preserved; signing itself was disabled only for the verification command.
- Existing dependency/debug-symbol and build-phase warnings remain. No archive, signing validation, runtime ad test, or binary/podspec publication was performed during verification.

The standard `Build Adapter` workflow is not a verified build path for this candidate: its Fastlane lane rebuilds the repository core SDK instead of consuming published Bidon 0.15.0. Use the local scripts above, or adapt and verify the workflow before releasing. Passing sdk_version=0.15.0 alone does not change the core source being compiled.

The standard Fastlane source revision parser accepts numeric adapter revisions only. This local candidate reports `4-bmplus.1` and is built with the scripts above; do not invoke the standard release lane unchanged. A future release needs explicit revision 4 / prerelease bmplus.1 and the same published-core build inputs and exact Bidon constraint, or an equivalent reviewed pipeline change.
