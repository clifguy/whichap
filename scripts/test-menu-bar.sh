#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$TASK_TEST_DIR/cache" WhichAP/MenuBarDisplay.swift Tests/MenuBarDisplayTests.swift -o "$TASK_TEST_DIR/menu-bar-tests"
"$TASK_TEST_DIR/menu-bar-tests"
