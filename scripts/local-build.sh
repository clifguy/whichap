#!/bin/bash
# Build and run a locally signed Debug app without a developer certificate.
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Install Xcode from the Mac App Store and complete its first-launch setup, then retry." >&2
  exit 1
fi

pkill -x WhichAP 2>/dev/null || true
xcodebuild build \
  -project WhichAP.xcodeproj \
  -scheme WhichAP \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath "$PROJECT_ROOT/build/DerivedData" \
  CONFIGURATION_BUILD_DIR="$PROJECT_ROOT/build/Debug"

APP="$PROJECT_ROOT/build/Debug/WhichAP.app"
codesign --verify --deep --strict "$APP"
open "$APP"
