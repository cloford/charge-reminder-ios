#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/ChargeReminder.xcodeproj"
SCHEME="ChargeReminder"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/charge-reminder-dd}"

DEVICE_ID="$(
  xcrun simctl list devices available |
    awk -F'[()]' '/^-- iOS / { ios = 1; next } /^--/ { ios = 0 } ios && /\([0-9A-F-]{36}\)/ { print $2; exit }'
)"

if [[ -z "$DEVICE_ID" ]]; then
  echo "No available iOS Simulator device found." >&2
  echo "Install an iOS Simulator runtime with: xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi

DESTINATION="platform=iOS Simulator,id=${DEVICE_ID}"

echo "Running Unit Test on ${DESTINATION}"
xcodebuild test \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO
