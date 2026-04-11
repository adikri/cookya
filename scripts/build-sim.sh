#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Stable simulator from `xcodebuild -showdestinations`
SIM_ID="90876E3F-96B3-49EC-A5E3-44A12F8DDA1C" # iPhone 16 (26.4)

DERIVED_DATA_PATH="/tmp/cookya-deriveddata-sim"

echo "Building cookya (Debug) for iOS Simulator id=${SIM_ID}"
echo "DerivedData: ${DERIVED_DATA_PATH}"

rm -rf "${DERIVED_DATA_PATH}"

xcodebuild clean build \
  -scheme cookya \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"

