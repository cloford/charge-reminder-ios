#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/ChargeReminder.xcodeproj/project.pbxproj"

usage() {
  cat <<'USAGE'
Usage:
  scripts/set-build-number.sh <build-number>
  scripts/set-build-number.sh --next

Updates CURRENT_PROJECT_VERSION in ChargeReminder.xcodeproj.
USAGE
}

current_build_number() {
  awk -F'= ' '/CURRENT_PROJECT_VERSION = / {
    value = $2
    gsub(/;/, "", value)
    print value
    exit
  }' "$PROJECT_FILE"
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

if [[ "$1" == "--next" ]]; then
  CURRENT="$(current_build_number)"
  if ! [[ "$CURRENT" =~ ^[0-9]+$ ]]; then
    echo "Current build number is not an integer: ${CURRENT}" >&2
    exit 1
  fi
  BUILD_NUMBER="$((CURRENT + 1))"
else
  BUILD_NUMBER="$1"
fi

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Build number must be a positive integer: ${BUILD_NUMBER}" >&2
  exit 2
fi

if [[ "$BUILD_NUMBER" -lt 1 ]]; then
  echo "Build number must be greater than 0: ${BUILD_NUMBER}" >&2
  exit 2
fi

perl -0pi -e "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PROJECT_FILE"

echo "Set CURRENT_PROJECT_VERSION to ${BUILD_NUMBER}"
