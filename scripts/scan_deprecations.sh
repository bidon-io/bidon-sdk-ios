#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/scan_deprecations.sh [repo_path]
# If repo_path is not provided, assumes this script is inside <repo>/scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
cd "$REPO"

OUT="build/reports/deprecations"
mkdir -p "$OUT"
RAW="$OUT/raw.txt"
: > "$RAW"

# 1) Collect deprecation lines from all xcactivitylogs (macOS bash 3.2 compatible)
find ~/Library/Developer/Xcode/DerivedData -type f -path "*/Logs/Build/*.xcactivitylog" -print0 2>/dev/null \
  | while IFS= read -r -d '' ACT; do
      if command -v file >/dev/null 2>&1 && file "$ACT" 2>/dev/null | grep -qi 'gzip'; then
        if command -v gzcat >/dev/null 2>&1; then
          gzcat "$ACT" 2>/dev/null | strings | grep -ai 'deprecated' || true
        else
          # Fallback if gzcat is missing — try zcat
          zcat "$ACT" 2>/dev/null | strings | grep -ai 'deprecated' || true
        fi
      else
        strings "$ACT" | grep -ai 'deprecated' || true
      fi
    done >> "$RAW"

# 1b) Collect from .xcresult bundles using xcresulttool (issues/messages)
find ~/Library/Developer/Xcode/DerivedData -type d \( -path "*/Logs/Build/*.xcresult" -o -path "*/Logs/Test/*.xcresult" \) 2>/dev/null \
  | while IFS= read -r RES; do
      if command -v xcrun >/dev/null 2>&1; then
        xcrun xcresulttool get --path "$RES" --format json --legacy 2>/dev/null \
          | grep -ai 'deprecated' || true
      fi
    done >> "$RAW"

# 2) Also scan the latest fastlane xcodebuild.log if present
LOG="$(ls -t ~/Library/Logs/fastlane/xcbuild/*/xcodebuild.log 2>/dev/null | head -n1 || true)"
if [ -f "$LOG" ]; then
  grep -ai 'deprecated' "$LOG" || true
fi >> "$RAW"

# 3) Unique lines
sort -u "$RAW" > "$OUT/deprecations.txt" || true

# 4) Detect adapters (multiple strategies)
ls -1 Adapters 2>/dev/null | grep -E '^BidonAdapter[A-Za-z]+' | sort -u > "$OUT/all_adapters.txt" || true
: > "$OUT/adapters.txt"

# 4a) Path-based extraction: look for "Adapters/<AdapterName>" directly in lines
grep -aoE 'Adapters/BidonAdapter[A-Za-z]+' "$OUT/deprecations.txt" \
  | sed -E 's#.*Adapters/##' \
  | sort -u >> "$OUT/adapters.txt" || true

if [ -s "$OUT/deprecations.txt" ] && [ -s "$OUT/all_adapters.txt" ]; then
  while IFS= read -r ADP; do
    if grep -aiqE "(Adapters/|/)?${ADP}(/|\\.| |:|$)|(^|[^A-Za-z0-9_])${ADP}([^A-Za-z0-9_]|$)" "$OUT/deprecations.txt"; then
      echo "$ADP" >> "$OUT/adapters.txt"
    fi
  done < "$OUT/all_adapters.txt"

  # 5) Build filename->adapter map to infer adapter by filenames in warnings
  : > "$OUT/basename_to_adapter.txt"
  find Adapters -type f \( -name '*.swift' -o -name '*.mm' -o -name '*.m' -o -name '*.h' -o -name '*.hpp' -o -name '*.cpp' \) 2>/dev/null \
    | while IFS= read -r P; do
        BN="$(basename "$P")"
        AD="$(echo "$P" | sed -E 's#^.*(BidonAdapter[[:alnum:]]+).*$#\1#')"
        if [ -n "$BN" ] && [ -n "$AD" ]; then
          echo "$BN|$AD" >> "$OUT/basename_to_adapter.txt"
        fi
      done
  sort -u -o "$OUT/basename_to_adapter.txt" "$OUT/basename_to_adapter.txt"

  # 6) Infer adapters by filenames appearing in warnings
  grep -Eo '[A-Za-z0-9_-]+\.(swift|mm|m|h|hpp|cpp)' "$OUT/deprecations.txt" | sort -u > "$OUT/basenames.txt" || true
  if [ -s "$OUT/basenames.txt" ] && [ -s "$OUT/basename_to_adapter.txt" ]; then
    while IFS= read -r BN; do
      AD="$(grep -E "^${BN}\\|" "$OUT/basename_to_adapter.txt" | cut -d '|' -f2 | sort -u)"
      [ -n "$AD" ] && echo "$AD" >> "$OUT/adapters.txt"
    done < "$OUT/basenames.txt"
  fi

  sort -u -o "$OUT/adapters.txt" "$OUT/adapters.txt"
fi

# Always ensure unique adapter names even if the conditional block above didn't run
sort -u -o "$OUT/adapters.txt" "$OUT/adapters.txt" 2>/dev/null || true

echo "Total deprecation lines: $(wc -l < "$OUT/deprecations.txt" 2>/dev/null || echo 0)"
echo "Adapters with deprecations:"
sed -E 's/^/- /' "$OUT/adapters.txt" || true

echo
echo "Sample lines (IronSource):"
grep -ai 'ironsource' "$OUT/deprecations.txt" | head -n 20 || true

echo
echo "Sample lines (AppLovin):"
grep -ai 'applovin' "$OUT/deprecations.txt" | head -n 20 || true


