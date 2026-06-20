## What & why

<!-- Briefly describe the change and the reason for it. -->

## Checklist

- [ ] `dart format` reports no changes
- [ ] `dart analyze --fatal-infos --fatal-warnings` is clean
- [ ] All package tests pass (`./tool/test_all.sh`)
- [ ] **Mutation testing run on new/changed source files** (`tool/mutation.sh ...`)

## Mutation evidence

<!--
Required when this PR adds or meaningfully changes logic.
Paste the mutation score for the files you touched, e.g.:

  packages/sheephead_engine/lib/src/card.dart — score 100% (0 survivors)

If any mutants survived, list them and either fix the test gap or explain why
the survivor is acceptable.
-->
