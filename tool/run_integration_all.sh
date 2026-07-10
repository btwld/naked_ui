#!/usr/bin/env bash
set -euo pipefail

# Runs each integration test file in packages/example/integration_test/components sequentially.
# Usage: bash tool/run_integration_all.sh [device_id]

DEVICE_FLAG=${1:-flutter-tester}

pushd packages/example >/dev/null

for f in integration_test/components/*.dart; do
  printf '\n=== Running %s ===\n' "$(basename "$f")"
  fvm flutter test -r compact "$f" -d "$DEVICE_FLAG"
done

popd >/dev/null
printf '\nAll integration component tests completed.\n'
