#!/usr/bin/env bash
# Usage: trunk_push.sh <podspec.json> [pod trunk push args...]
# Set POD_CMD to run pod some other way (default: "pod").
#
# Trunk often answers "Calling the GitHub commit API timed out" although it has
# accepted the spec. So the version is checked on trunk: if it is there, the
# push counts as done, both before pushing (re-runs) and after a failed push.
set -euo pipefail

spec="$1"; shift
name=$(jq -r '.name' "$spec")
version=$(jq -r '.version' "$spec")
read -ra pod <<< "${POD_CMD:-pod}"

on_trunk() {
  # 302 (redirect to the spec) when the version exists, 404 when it does not.
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://trunk.cocoapods.org/api/v1/pods/${name}/specs/${version}" || true)
  [[ "$code" == 2* || "$code" == 3* ]]
}

if on_trunk; then
  echo "${name} ${version} is already on trunk, skipping push"
  exit 0
fi

echo "Running: ${pod[*]} trunk push $spec $*"
if "${pod[@]}" trunk push "$spec" "$@"; then
  exit 0
fi

for _ in 1 2 3 4 5 6; do
  sleep 10
  if on_trunk; then
    echo "::warning::pod trunk push failed, but ${name} ${version} is on trunk"
    exit 0
  fi
done

echo "::error::${name} ${version} is not on trunk"
exit 1
