#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Stable simulator from `xcodebuild -showdestinations`
SIM_ID="90876E3F-96B3-49EC-A5E3-44A12F8DDA1C" # iPhone 16 (26.4)

DERIVED_DATA_PATH="/tmp/cookya-deriveddata-tests"

# Boot the simulator if not already running.
# Skipping this step is the #1 cause of slow/stale test runs — a cold boot adds
# 60-120 seconds and sometimes leaves xcodebuild in a hung state.
SIM_STATE=$(xcrun simctl list devices | grep "${SIM_ID}" | grep -oE 'Booted|Shutdown|Booting' | head -1 || echo "unknown")
if [[ "${SIM_STATE}" != "Booted" ]]; then
  echo "Booting simulator ${SIM_ID} (was: ${SIM_STATE})..."
  xcrun simctl boot "${SIM_ID}" 2>/dev/null || true
  echo -n "Waiting for Booted..."
  until xcrun simctl list devices | grep "${SIM_ID}" | grep -q "Booted"; do
    sleep 2
    echo -n "."
  done
  echo " ready."
else
  echo "Simulator already Booted."
fi

echo "Testing cookya (Debug) on iOS Simulator id=${SIM_ID}"
echo "DerivedData: ${DERIVED_DATA_PATH}"

rm -rf "${DERIVED_DATA_PATH}"

xcodebuild test \
  -scheme cookya \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"
