# CLAUDE.md

Standing instructions for Claude Code working in this repository. Read this
before writing code. When something here conflicts with a default habit, this
file wins. When a Sheephead rule is unclear, **ask — do not invent rules.** As new information is introduced, feel free to suggests updates for this file.

---

## What this project is

A configurable **Sheephead** game: a pure-Dart engine plus a terminal harness
now, a Flutter app (web/iOS/Android) and a Dart multiplayer server later. The
product goal is "chess.com for Sheephead" — learn, compete, belong — with a
strong emphasis on **teaching the game** and on **offline solo play against a
convincing rules-based AI**. Offline play is why the engine must be pure Dart
and run on-device.

- Repo: https://github.com/justinleebehnke/sheephead-dart
- Human-oriented background lives in `PROJECT_CONTEXT.md`; the full story list in
  `BACKLOG.md`. Keep all three consistent if you change project direction.

---

## Repository layout

```
packages/
  sheephead_engine/   # pure Dart: cards, deal, rules, scoring, AI. No UI/IO/network.
  sheephead_cli/      # terminal harness (play + manual testing)
tool/                 # scripts: test_all.sh, mutation.sh, hooks/, install-hooks.sh
.github/workflows/    # CI
```

This is a **pub workspace**. The root `pubspec.yaml` lists members under
`workspace:`; each member declares `resolution: workspace`. Run `dart pub get`
once at the root.

Dart package conventions, follow them:
- `lib/src/**` = private internals.
- `lib/<package>.dart` = the public API; expose internals via `export`.
- `bin/**` = runnable entrypoints (have `main()`).
- `test/**` = tests named `*_test.dart`.

---

## Commands

```bash
dart pub get                                          # at repo root; resolves the workspace
./tool/test_all.sh                                    # run every package's tests
(cd packages/sheephead_engine && dart test)           # one package
dart format --output none --set-exit-if-changed .     # STRICT format check (no writes)
dart analyze --fatal-infos --fatal-warnings           # static analysis; infos are fatal
./tool/mutation.sh path/a.dart,path/b.dart            # on-demand mutation testing (local only)
./tool/install-hooks.sh                               # one-time: enable the pre-push gate
```

---

## How to work here (non-negotiable)

1. **TDD, outside-in (London style).** Write or modify a **failing test first**,
   then write the minimum code to make it pass, then refactor. Never add
   production code without a test that drove it.
2. **Small changes.** One concept per change/PR. Reviews often happen on a phone,
   so keep diffs short and self-contained — one short file and its test is ideal.
   Prefer several tiny PRs over one large one.
3. **Keep the gates green before committing.** A change is not done until all
   three pass locally (or in CI):
   - `dart format --output none --set-exit-if-changed .` reports no changes,
   - `dart analyze --fatal-infos --fatal-warnings` is clean,
   - `./tool/test_all.sh` passes.
   Do not fight the formatter; run `dart format .` and accept its output.
4. **Mutation testing is on-demand, not in CI.** After adding or changing engine
   logic, run `./tool/mutation.sh <changed files>` and report the score. Surviving
   mutants are test gaps — close them or explain why a survivor is acceptable.
5. **Never commit generated artifacts.** `mutation-test-report/`, `build/`, and
   `.dart_tool/` are git-ignored and must never appear under `lib/` or in a commit.

---

## Architecture invariants (do not violate)

- **The engine depends on nothing.** Dependency direction is strictly
  `cli → engine` (and later `app → engine`, `server → engine`). The engine must
  never import Flutter, dart:io, networking, or any sibling package. If you feel
  the urge to import UI/IO into the engine, the design is wrong — stop and ask.
- **Config is the domain model.** Everything that varies between Sheephead
  variants lives in an immutable `GameConfig` value object (as data) or in an
  **injected strategy** (when behavior, not just a parameter, varies). Do **not**
  scatter `if (spitzer) … / if (stealAllowed) …` branches through the engine.
  Adding a variant should mean adding a config/strategy, not editing core logic.
- **`Card` knows only suit and rank — never whether it is trump.** Trump-ness
  depends on `GameConfig` (standard vs Spitzer), so it is computed by the engine
  against the config, not stored on the card.
- **Randomness is injected and seeded.** Wrap an injected `Random` (a `Shuffler`);
  never call `Random()` directly inside game logic. Every test that touches
  randomness passes a seed so runs are deterministic.
- **Hidden information is enforced at the engine boundary.** The engine holds a
  master state and derives a per-player view containing only what that player may
  see. A `PlayerView` must never carry another player's concealed cards or the
  blind (except where the rules explicitly allow). Treat a leak here as a bug.

---

## The configured default variant: 4-player Spitzer

These are the project's house rules — the default `GameConfig`. **Do not
substitute canonical/other Sheephead rules.** Other variants are supported via
configuration, not by changing these.

- 4 players, 6 cards each, 2-card blind.
- **26-card deck:** the 32-card Sheephead deck with the 7s and 8s removed from the
  fail suits (remove 7♣ 7♠ 7♥ 8♣ 8♠ 8♥). 7♦ and 8♦ remain — diamonds are trump.
- **Spitzer trump order:** the 7♦ is the second-highest card, immediately behind
  the Q♣.
- **Steal the blind:** after the picker buries and before the first lead, a player
  may announce a steal. The option may be shown before the bury, but the
  declaration locks the moment the picker buries, so all players are notified
  before the first card. Stealing = going alone; the stealer does not see the
  blind. Configurable on/off.
- **Doubles on all-pass:** if everyone passes, the hand is doubled; pass again →
  the next two hands are doubled, escalating. Same dealer redeals (configurable).
- **Cut-card rule:** a designated cut card triggers a round of doubles
  (configurable).
- **Picker-no-trick penalty:** if the picker takes no trick, apply a configurable
  penalty, typically ~4× base points.

Future config axes to keep in mind so they stay data, not new code paths:
5-player with the dealer sitting out; leaster as an alternative all-pass
resolution; crack/recrack doublers; bury-legality rules.

---

## AI design (when you reach it)

- A stable `SheepheadAi` interface: `decidePick`, `decideBury`, `decidePlay`,
  `declareSteal`. Use **separate decision logic for picker-role vs defender-role.**
- Implement strategic knowledge as **rule objects that both score a decision and
  can explain themselves**, so the same rule powers AI play and the human coaching
  hint. (Example concept: "keep stopper.")
- Provide a `RandomAi` baseline and a headless simulation runner (seeded) to
  benchmark any rules-based AI against random over large samples. AI changes
  should be validated by simulation, not vibes.

---

## Workflow / git

- Trunk-based. The maintainer may commit directly to `main` behind the local
  pre-push hook. **All agent-generated work should go through a branch + pull
  request** so CI (`verify`) gates it before merge; the maintainer often merges
  from a phone once the check is green.
- Never use `git push --no-verify`. Never weaken the gates to make something pass.
- CI runs format, analyze, and tests on push to `main` and on every PR. A red
  `main` is a stop-the-line event: fixing it precedes all other work.
- `pubspec.lock` is committed (the workspace will contain an app).

