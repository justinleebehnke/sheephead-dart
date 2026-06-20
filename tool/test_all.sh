#!/usr/bin/env bash
# Resolve the workspace once, then run each package's test suite.
set -euo pipefail

cd "$(dirname "$0")/.."
dart pub get

for pkg in packages/*/; do
  if [ -d "${pkg}test" ]; then
    echo
    echo "== Testing ${pkg} =="
    (cd "$pkg" && dart test)
  fi
done
