#!/usr/bin/env bash
# Fast re-run of tests without rebuilding. Use after test-sim.sh has done a
# full build at least once. Assumes the simulator is already Booted (if not,
# run test-sim.sh instead).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

SIM_ID="90876E3F-96B3-49EC-A5E3-44A12F8DDA1C" # iPhone 16 (26.4)
DERIVED_DATA_PATH="/tmp/cookya-deriveddata-tests"

SIM_STATE=$(xcrun simctl list devices | grep "${SIM_ID}" | grep -oE 'Booted|Shutdown|Booting' | head -1 || echo "unknown")
if [[ "${SIM_STATE}" != "Booted" ]]; then
  echo "Simulator not Booted (${SIM_STATE}). Run ./scripts/test-sim.sh for a full run."
  exit 1
fi

echo "Quick test (test-without-building) on ${SIM_ID}"

xcodebuild test-without-building \
  -scheme cookya \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"
