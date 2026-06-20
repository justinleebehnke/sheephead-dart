# Contributing

## Branching model

This repo uses **trunk-based development**.

- **The maintainer** commits directly to `main`. A local pre-push hook
  (`tool/install-hooks.sh`) runs formatting, analysis, and tests before any push
  is allowed to land, keeping `main` always green.
- **Everyone else** works on a fork or branch and opens a **pull request**.
  Direct pushes to `main` are blocked for non-maintainers. Your PR must pass CI
  (format, analyze, test) before it can merge.

## Required checks for a PR

Before requesting review, make sure:

1. `dart format --output none --set-exit-if-changed .` reports no changes.
2. `dart analyze --fatal-infos --fatal-warnings` is clean.
3. All package tests pass (`./tool/test_all.sh`).

## Mutation testing (required for new or substantially changed logic)

Passing tests prove your code does something; **mutation testing proves your
tests would notice if it did the wrong thing.** Any PR that adds or meaningfully
changes engine logic must include evidence that mutation testing was run on the
affected files.

Run it on your changed files, Stryker-style:

```bash
./tool/mutation.sh packages/sheephead_engine/lib/src/your_file.dart
```

Then, in the PR description, **note the mutation score** for the files you
touched and address any surviving mutants (each survivor is a test gap). If a
survivor is intentionally left, explain why.
