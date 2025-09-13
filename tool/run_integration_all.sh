#!/usr/bin/env bash
set -euo pipefail

# Runs each integration test file in example/integration_test/components sequentially.
# Usage: bash tool/run_integration_all.sh [device_id]

DEVICE_FLAG=${1:-macos}

pushd example >/dev/null

for f in integration_test/components/*.dart; do
  echo "\n=== Running $(basename "$f") ==="
  flutter test -r compact "$f" -d "$DEVICE_FLAG" --no-enable-impeller
done

popd >/dev/null
echo "\nAll integration component tests completed."

