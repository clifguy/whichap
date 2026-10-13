#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$TASK_TEST_DIR/cache" WhichAP/ProviderLookup.swift Tests/ProviderMenuPerformance.swift -o "$TASK_TEST_DIR/provider-menu-performance"
"$TASK_TEST_DIR/provider-menu-performance"
