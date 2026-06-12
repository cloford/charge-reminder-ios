#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/ChargeReminder.xcodeproj"
PROJECT_FILE="$PROJECT_PATH/project.pbxproj"
SCHEME="ChargeReminder"
CONFIGURATION="Release"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/ChargeReminder.xcarchive"
EXPORT_PATH="$BUILD_DIR/TestFlightExport"
EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
RUN_TESTS=1
BUILD_NUMBER="--next"

usage() {
  cat <<'USAGE'
Usage:
  scripts/upload-testflight.sh [options]

Options:
  --build-number <number>  Set an explicit TestFlight build number.
  --no-bump               Keep the current build number.
  --skip-tests            Archive without running Unit Test first.
  --archive-only          Create an archive but do not upload it.
  -h, --help              Show this help.

Default behavior:
  1. Increment CURRENT_PROJECT_VERSION.
  2. Run Unit Test.
  3. Create a Release archive for iOS.
  4. Upload the archive to App Store Connect/TestFlight.

Prerequisites:
  - Xcode is installed.
  - Xcode is signed in with the Apple Developer account.
  - The ChargeReminder target has valid Signing & Capabilities settings.
USAGE
}

ARCHIVE_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-number)
      if [[ $# -lt 2 ]]; then
        echo "--build-number requires a value." >&2
        exit 2
      fi
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --no-bump)
      BUILD_NUMBER=""
      shift
      ;;
    --skip-tests)
      RUN_TESTS=0
      shift
      ;;
    --archive-only)
      ARCHIVE_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

current_build_number() {
  awk -F'= ' '/CURRENT_PROJECT_VERSION = / {
    value = $2
    gsub(/;/, "", value)
    print value
    exit
  }' "$PROJECT_FILE"
}

marketing_version() {
  awk -F'= ' '/MARKETING_VERSION = / {
    value = $2
    gsub(/;/, "", value)
    print value
    exit
  }' "$PROJECT_FILE"
}

development_team() {
  awk -F'= ' '/DEVELOPMENT_TEAM = / {
    value = $2
    gsub(/;/, "", value)
    if (value != "") {
      print value
      exit
    }
  }' "$PROJECT_FILE"
}

if [[ -n "$BUILD_NUMBER" ]]; then
  "$ROOT_DIR/scripts/set-build-number.sh" "$BUILD_NUMBER"
fi

CURRENT_BUILD="$(current_build_number)"
MARKETING_VERSION="$(marketing_version)"
TEAM_ID="$(development_team)"

if [[ -z "$TEAM_ID" ]]; then
  echo "Could not find DEVELOPMENT_TEAM in $PROJECT_FILE." >&2
  echo "Open Xcode and select a Team in Signing & Capabilities first." >&2
  exit 1
fi

echo "Preparing ChargeReminder ${MARKETING_VERSION} (${CURRENT_BUILD})"

if [[ "$RUN_TESTS" -eq 1 ]]; then
  "$ROOT_DIR/scripts/test-ios.sh"
fi

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>upload</string>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

echo "Archiving to $ARCHIVE_PATH"
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates

if [[ "$ARCHIVE_ONLY" -eq 1 ]]; then
  echo "Archive created: $ARCHIVE_PATH"
  exit 0
fi

echo "Uploading to App Store Connect/TestFlight"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -allowProvisioningUpdates

echo "Uploaded ChargeReminder ${MARKETING_VERSION} (${CURRENT_BUILD}) to App Store Connect."
