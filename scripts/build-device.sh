#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Matches Xcode run destination: iOS device (set this locally)
# Usage:
#   COOKYA_DEVICE_ID="..." ./scripts/build-device.sh
: "${COOKYA_DEVICE_ID:?Set COOKYA_DEVICE_ID from `xcodebuild -scheme cookya -showdestinations`}"

# IMPORTANT: device CLI builds must not write DerivedData inside the repo
# (File Provider xattrs can cause codesign failures).
DERIVED_DATA_PATH="/tmp/cookya-deriveddata-device"

echo "Building cookya (Debug) for iOS device id=${COOKYA_DEVICE_ID}"
echo "DerivedData: ${DERIVED_DATA_PATH}"

rm -rf "${DERIVED_DATA_PATH}"

xcodebuild clean build \
  -scheme cookya \
  -configuration Debug \
  -destination "platform=iOS,id=${COOKYA_DEVICE_ID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"

