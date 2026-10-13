#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TASK_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
python3 - "$TASK_TEST_DIR/ReachabilityChecks.swift" <<'PY'
from pathlib import Path
import sys
source = Path('WhichAP/WiFiMonitor.swift').read_text()
marker = 'protocol ReachabilityMonitorDelegate:'
assert source.count(marker) == 1
Path(sys.argv[1]).write_text(source[source.index(marker):] + '\n' + Path('Tests/ReachabilityMonitorTests.swift').read_text())
PY
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" -module-cache-path "$TASK_TEST_DIR/cache" WhichAP/ProviderLookup.swift "$TASK_TEST_DIR/ReachabilityChecks.swift" -o "$TASK_TEST_DIR/reachability-tests"
"$TASK_TEST_DIR/reachability-tests"
