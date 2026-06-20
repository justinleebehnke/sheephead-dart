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
