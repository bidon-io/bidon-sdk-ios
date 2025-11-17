#!/usr/bin/env bash
set -euo pipefail

POD=""
FROM_VER=""
TO_VER=""
ADAPTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pod) POD="$2"; shift 2 ;;
    --from) FROM_VER="$2"; shift 2 ;;
    --to) TO_VER="$2"; shift 2 ;;
    --adapter) ADAPTER="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

echo "Build request:"
echo "  POD     : ${POD}"
echo "  FROM    : ${FROM_VER}"
echo "  TO      : ${TO_VER}"
echo "  ADAPTER : ${ADAPTER}"

if [[ -z "${POD}" || -z "${TO_VER}" ]]; then
  echo "Missing required metadata" >&2
  exit 1
fi

# Ensure CocoaPods binary path (mirrors existing workflow approach)
GEM_HOME=$(/opt/homebrew/opt/ruby@3.2/bin/gem env home)
POD_BIN=$(command -v pod || echo "$GEM_HOME/bin/pod")
echo "Using POD_BIN=${POD_BIN}"

# Example placeholder: run lightweight validation. Adjust to your real adapter build logic.
echo "Running adapter validation build for ${ADAPTER:-<unspecified>} with ${POD}=${TO_VER}…"

# Optionally, re-run install to ensure lockfile consistency (skip repo update for speed)
"${POD_BIN}" install || true

# Optionally execute tests/build (uncomment and tune if desired)
# RUNTIME_ID=$(xcrun simctl list runtimes -j | /opt/homebrew/bin/jq -r '[.runtimes[] | select((.availability?=="(available)" or .isAvailable==true) and (.identifier|test("iOS"))) | .identifier] | sort | last')
# DEST_ID=$(xcrun simctl list devices -j | /opt/homebrew/bin/jq -r --arg rid "$RUNTIME_ID" '((.devices[$rid] // []) | map(select(.isAvailable==true)) | map(.udid) | .[0])')
# xcodebuild \
#   -workspace "BidOn.xcworkspace" \
#   -scheme "AdaptersTests" \
#   -sdk iphonesimulator \
#   -destination "id=$DEST_ID" \
#   -quiet \
#   -destination-timeout 120 \
#   test | xcbeautify || true

echo "Build script finished."


