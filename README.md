# Sheephead

A configurable Sheephead engine in pure Dart, plus a terminal harness to play it.

This repo is a **pub workspace** (monorepo). One shared dependency resolution
across all packages.

```
sheephead/
  pubspec.yaml              # workspace root (not a shippable package)
  packages/
    sheephead_engine/       # pure Dart game logic — no UI, no I/O
    sheephead_cli/          # terminal harness that drives the engine
  tool/
    test_all.sh             # run every package's tests
```

## First run

```bash
dart pub get            # at the repo root — resolves the whole workspace
./tool/test_all.sh      # runs tests in every package
```

Or test one package at a time:

```bash
cd packages/sheephead_engine && dart test
cd packages/sheephead_cli    && dart test
```

## Mutation testing

Mutation testing checks the quality of the *tests*, not the code: it makes small
changes ("mutants") to a source file and verifies that some test fails. A mutant
that survives means a behavior your tests don't actually pin down.

It is **not** part of the push or CI gate — it's slow, and it's run on demand,
on just the files you care about (the same way Stryker is used in the
TypeScript world).

Run it Stryker-style with a comma-separated list of target files:

```bash
./tool/mutation.sh packages/sheephead_engine/lib/src/card.dart
./tool/mutation.sh packages/sheephead_engine/lib/src/card.dart,packages/sheephead_engine/lib/src/deck.dart
```

First-time setup (per package you intend to mutate):

```bash
(cd packages/sheephead_engine && dart pub add --dev mutation_test)
```

Contributors: see `CONTRIBUTING.md` — PRs that add or change logic must include
mutation evidence.
