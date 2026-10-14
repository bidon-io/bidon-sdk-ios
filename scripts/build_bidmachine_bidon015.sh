#!/usr/bin/env bash
# Local-only build, packaging, and SDK-1338 tests. Never publishes artifacts.
set -euo pipefail
BIDON_COMPAT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIDON_COMPAT_EXPORT="${1:?Pass the existing Word Search iOS export directory}"
BIDON_COMPAT_SIMULATOR="${2:?Pass an available iOS Simulator UDID}"
BIDON_COMPAT_OUTPUT="$BIDON_COMPAT_ROOT/build/bidmachine-bidon015"
cd "$BIDON_COMPAT_ROOT"
if [[ -e "$BIDON_COMPAT_OUTPUT/BidonAdapterBidMachine-3.8.0.4-bmplus.1/BidonAdapterBidMachine.xcframework" || -e "$BIDON_COMPAT_OUTPUT/SDK1338-tests.xcresult" ]]; then
  echo "Previous build exists. Preserve/move build/bidmachine-bidon015 before rebuilding." >&2
  exit 1
fi
ruby scripts/build_bidmachine_bidon015.rb "$BIDON_COMPAT_EXPORT"
for BIDON_COMPAT_SDK in iphoneos iphonesimulator; do
  if [[ "$BIDON_COMPAT_SDK" == iphoneos ]]; then
    BIDON_COMPAT_DESTINATION='generic/platform=iOS'
  else
    BIDON_COMPAT_DESTINATION='generic/platform=iOS Simulator'
  fi
  xcodebuild build -project "$BIDON_COMPAT_OUTPUT/Compatibility.xcodeproj" \
    -scheme BidonAdapterBidMachine -configuration Release -sdk "$BIDON_COMPAT_SDK" \
    -destination "$BIDON_COMPAT_DESTINATION" -derivedDataPath "$BIDON_COMPAT_OUTPUT/DerivedData" \
    CODE_SIGNING_ALLOWED=NO > "$BIDON_COMPAT_OUTPUT/build-$BIDON_COMPAT_SDK.log" 2>&1
done
# Keep existing candidates intact: xcodebuild fails rather than overwrites this output.
xcodebuild -create-xcframework \
  -framework "$BIDON_COMPAT_OUTPUT/DerivedData/Build/Products/Release-iphoneos/BidonAdapterBidMachine.framework" \
  -framework "$BIDON_COMPAT_OUTPUT/DerivedData/Build/Products/Release-iphonesimulator/BidonAdapterBidMachine.framework" \
  -output "$BIDON_COMPAT_OUTPUT/BidonAdapterBidMachine-3.8.0.4-bmplus.1/BidonAdapterBidMachine.xcframework"
xcodebuild test -project "$BIDON_COMPAT_OUTPUT/Compatibility.xcodeproj" \
  -scheme BidonAdapterBidMachine -configuration Debug \
  -destination "platform=iOS Simulator,id=$BIDON_COMPAT_SIMULATOR" \
  -derivedDataPath "$BIDON_COMPAT_OUTPUT/DerivedData" \
  -resultBundlePath "$BIDON_COMPAT_OUTPUT/SDK1338-tests.xcresult" \
  CODE_SIGNING_ALLOWED=NO > "$BIDON_COMPAT_OUTPUT/test.log" 2>&1
