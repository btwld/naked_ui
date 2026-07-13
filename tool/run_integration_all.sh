#!/usr/bin/env bash
set -euo pipefail

# Runs integration test files in packages/example/integration_test/components
# sequentially.
# Usage: bash tool/run_integration_all.sh [device_id] [component_glob]
#   component_glob (optional) limits the run, e.g. "naked_button*" for a
#   fast CI smoke of the script itself.

DEVICE_FLAG=${1:-macos}
COMPONENT_GLOB=${2:-*}

cd "$(dirname "$0")/.."
pushd packages/example >/dev/null

for f in integration_test/components/${COMPONENT_GLOB}.dart; do
  printf '\n=== Running %s ===\n' "$(basename "$f")"
  flutter test -r compact "$f" -d "$DEVICE_FLAG" --no-enable-impeller
done

popd >/dev/null
printf '\nAll integration component tests completed.\n'

