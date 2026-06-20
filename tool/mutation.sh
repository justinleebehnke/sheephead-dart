#!/usr/bin/env bash
# On-demand mutation testing, Stryker-style.
#
# Mutation testing is deliberately NOT part of the push/CI gate — it's slow and
# you run it when a change warrants checking that your *tests* actually catch
# regressions, not merely that they pass. Pass a comma-separated list of target
# source files (paths relative to the repo root), just like Stryker.
#
# Usage:
#   ./tool/mutation.sh packages/sheephead_engine/lib/src/card.dart
#   ./tool/mutation.sh packages/sheephead_engine/lib/src/card.dart,packages/sheephead_engine/lib/src/deck.dart
#
# One-time setup (per package you'll mutate), so `dart run mutation_test` works:
#   (cd packages/sheephead_engine && dart pub add --dev mutation_test)
#   (cd packages/sheephead_cli    && dart pub add --dev mutation_test)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# All reports go to one ignored folder at the repo root, never next to source.
REPORT_DIR="$ROOT/mutation-test-report"

if [ $# -lt 1 ]; then
  echo "usage: $0 <file1[,file2,...]>   (paths relative to repo root)" >&2
  exit 2
fi

# Split the comma-separated argument into an array.
IFS=',' read -r -a TARGETS <<< "$1"

# mutation_test must run from inside a workspace package (it needs lib/ and a
# working `dart test`). Group the requested files by their package.
declare -A BY_PKG
for raw in "${TARGETS[@]}"; do
  f="$(printf '%s' "$raw" | xargs)"            # trim surrounding whitespace
  [ -n "$f" ] || continue
  if [ ! -f "$f" ]; then
    echo "✗ not a file: $f" >&2
    exit 1
  fi
  case "$f" in
    packages/*/*)
      pkg="packages/$(printf '%s' "$f" | cut -d/ -f2)"
      rel="${f#"$pkg"/}"
      BY_PKG["$pkg"]+="$rel "
      ;;
    *)
      echo "✗ target must live under packages/<name>/: $f" >&2
      exit 1
      ;;
  esac
done

# Run mutation_test per package, scoped to just the requested files.
for pkg in "${!BY_PKG[@]}"; do
  echo
  echo "▶ mutation testing in $pkg"
  echo "  files: ${BY_PKG[$pkg]}"
  pkg_name="$(basename "$pkg")"
  # -o sends the report to one repo-root folder (per package), not next to source.
  # shellcheck disable=SC2086  # intentional word-splitting: pass each file as a separate arg
  ( cd "$pkg" && dart run mutation_test ${BY_PKG[$pkg]} -o "$REPORT_DIR/$pkg_name" )
done

echo
echo "✓ Mutation run complete. Surviving mutants = gaps in your tests."
echo "  Reports: $REPORT_DIR/<package>/  (this folder is git-ignored)."
