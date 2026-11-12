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

1. **TDD, outside-in (London style), double loop.** Each story starts with a
   failing **acceptance spec** (outer loop — see "Acceptance tests" below), which
   is driven green through inner RED → GREEN → REFACTOR unit-test cycles (see
   "AAID workflow" below). Never add production code without a test that drove it.
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
- **The engine's public surface is commands, results, and views — not internal
  events.** Clients (CLI, AI, later a server) submit a sealed `Command`, dispatched
  via an exhaustive `switch` — never a registry/lookup that the compiler can't check
  for completeness. The engine returns a sealed `CommandResult`: `Accepted()` or
  `Rejected(reason)`. **Never a thrown exception across this boundary** — errors are
  data, same as everything else here. Internally, `Event`s fold through a pure
  `apply(state, event) -> state` reducer so `MasterGameState` is always *derived
  from* its event history, never separately mutated — but `Event` is engine-private
  and never crosses the boundary. Clients observe state changes by implementing
  `GameObserver.onChanged()` and pull their view via `GameSession.viewFor(PlayerId)`.
  Every type that crosses this boundary (`Command`, `CommandResult`, `GameConfig`,
  `PlayerView`, `PlayerId`) is plain data — no function-typed fields, no behavior
  crossing the boundary. See `BACKLOG.md` Epic 2.
- **The engine decides the phase; clients never infer it.** A `PlayerView` carries
  a sealed `PhaseView` discriminator naming the phase that view was captured in
  (pick, all-pass, bury, steal, trick-play, trick-result, hand-result, game-result,
  …). Each variant carries *exactly and only* the fields that phase requires, as
  non-nullable — so "because we are in phase X, fields Y and Z are present" is a
  compile-time guarantee, not a convention. The engine is the sole authority on
  which phase it is and picks the right variant (e.g. a last-hand all-pass emits
  `GameResultPhaseView`, not `AllPassPhaseView`, because there is no redeal).
  Clients — CLI, AI, later a server — **`switch` exhaustively over `PhaseView`**
  and never reconstruct the phase from a bag of optional flags or heuristics like
  hand size. A phase is a property of the game state on *every* update, orthogonal
  to `isMyTurnToAct` (whether *this* player is the one to act within it). Adding a
  phase means adding a `PhaseView` variant and letting the compiler's exhaustiveness
  check flag every client that must handle it.
- **The engine is a pure state machine; it has no notion of waiting.** The engine
  is the accumulated result of all events applied so far. It cannot produce new
  events until a `Command` is submitted — not because it is "blocked," but because
  there is nothing to process. Both AI and UI are external producers of `Command`s
  and `GameObserver` implementors — neither has privileged access to engine
  internals. Display pacing (delays between events, holding the screen at
  trick-end until the human presses Enter) is a UI concern, not an engine concern.
  The distinction matters: an **action pause** (the engine requires a `Command`
  before it can produce more events) is a game-state dependency; a **display pause**
  (UI waiting for the human to acknowledge a completed trick) is purely
  presentational and must not affect the engine or other players.
- **Result phases are transient snapshots the engine passes *through*, never
  acknowledgment gates.** One `Command` can drive a *sequence* of view snapshots:
  the engine folds all consequent events and emits a snapshot at each meaningful
  state it moves through — including the "result" phases (`TrickResult`,
  `HandResult`, the doubled-redeal `AllPass`) — then rests at the next genuine
  decision point (the next action pause). There is **no** continue/acknowledge
  `Command`: leaving a result phase is not gated on input, which is exactly why
  "the engine has already moved on" holds and why **AI never pauses** (it reacts
  only to snapshots where it must act, ignoring result frames). The *human* client
  gets its pacing by **buffering the snapshot stream** in the presenter — holding a
  result frame on screen until the player presses Enter, then revealing the next
  buffered frame. So e.g. playing the 4th card of a trick emits a `TrickResult`
  snapshot and then the next `TrickPlay` (or `HandResult` → auto-dealt next
  `Pick`) snapshot; the engine rests only at the next lead/decision, and the
  presenter paces the frames between. This buffering is a UI-layer concern; the
  engine and AI are unaffected.

---

## CLI display constraints (named assumptions)

The terminal harness targets a standard **80-column terminal**. This is a
deliberate, named constraint — not an oversight. Consequences:

- **`GamePhase` implementations own their visual layout.** They format content
  with 80-column line widths in mind. There is no runtime layout negotiation
  between `GamePhase` and `ScreenFrame`.
- **`ScreenFrame` is thin chrome only.** Its job is: ANSI clear-screen, a
  consistent error zone, and any fixed header/footer. It does not reflow or
  reposition content.
- **No dynamic terminal sizing in v1.** If the user's terminal is narrower than
  80 columns, content may wrap. That is acceptable for the CLI harness. The
  Flutter app (later) will handle responsive layout properly.

If you find yourself passing terminal dimensions into `GamePhase`, or making
`ScreenFrame` responsible for spatial layout, stop — the design has drifted from
these named constraints. Either accept 80 columns or move the discussion to the
Flutter app layer.

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
- **Partner via Jack of Diamonds:** unless the picker goes alone, their partner is
  whoever holds the J♦ — unknown to the table until revealed by play. The picker
  may declare **"chop"** at bury time to decline this partnership and go alone
  instead. **Illegal to chop while holding J♦ yourself** (there is no partner to
  cut off, so the announcement would mislead the table into believing one exists
  elsewhere). **Illegal to bury J♦ without announcing it** (burying it also
  removes any possible partner, and the table must know). A picker who secretly
  holds J♦ cannot legally chop and therefore has no way to block a steal —
  stealing proceeds normally in that case; this is an accepted asymmetry, not a
  bug.
- **Steal the blind:** offered only to players who never got a chance to pick —
  i.e., whoever comes after the picker in the pick/pass turn order (left of
  dealer → ... → dealer last); if the dealer picked, no one is offered a steal.
  Never offered at all if the picker declared chop. Offered only after the bury
  concludes (not before — gated on the chop/J♦ rules above), in turn order
  starting left of the picker and ending at the dealer; default is decline (no
  prompt friction); the first player to accept gets it and no one else is asked.
  Stealing = going alone; the stealer does not see the blind. Configurable on/off.
- **Doubles on all-pass:** a doubles hand always pays **×2** — never a larger
  multiplier, and this is not configurable. If everyone passes, the same dealer
  redeals and the redealt hand is a doubles hand. Passing out a hand that is
  *already* doubles pushes **another** doubles hand onto a stack: the redeal stays
  doubles *and* one more future hand becomes doubles too, so several ×2 hands can
  queue up to be worked through (no limit). Escalation is depth on this stack, not
  a bigger multiplier. Same dealer redeals (configurable). Do not model this as a
  multiplier value; track a count of pending doubles hands.
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
  Each method returns the `Command` to submit — the AI is an external
  command-producer against the same contract as any other client, with no
  privileged access to engine internals.
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

---

## Acceptance tests (Dave Farley's four layers)

Being introduced in `BACKLOG.md` Epic A; until the walking skeleton lands, the
inner AAID loop is the only loop. Target shape:

1. **Executable specifications** — written once, in Sheephead domain language,
   from the player's point of view. *What*, never *how* (no ANSI, stdin, HTTP).
2. **DSL** — shared vocabulary the specs call: card shorthand, sensible
   defaults, aliasing for isolation.
3. **Protocol drivers** — the only layer that knows how to talk to the system.
   One per channel: `CliDriver` now, a server driver later, optionally an
   in-process engine driver for fast feedback (never a replacement for an
   outside-in driver).
4. **System under test** — the real program, black-box, through its public
   interfaces. No back doors into engine state; preconditions (the deal, who
   controls each seat) are set through deliberate test hooks at the edge
   (flags/config on the composition root).

These live in their own package (`packages/sheephead_acceptance`), which may
depend on both `cli` and `engine`; the `cli → engine` rule is unchanged.
Existing engine/CLI tests remain as component/unit tests.

---

## AAID workflow

You are assisting a developer who may use `AAID` (Augmented AI Development) - a workflow where:

- The developer maintains architectural control and reviews all code
- You (the AI) generate tests and implementation following TDD discipline
- The workflow proceeds through strict RED → AWAIT USER REVIEW → GREEN → AWAIT USER REVIEW → REFACTOR → AWAIT USER REVIEW cycles
- Every phase requires developer review before proceeding
- Tests guide development based on provided specifications

Your role: Generate code when requested, follow TDD rules strictly when in TDD mode, and always STOP between phases.

### The Full AAID Workflow Sequence

The complete AAID workflow follows this order:

1. **Stage 1: Context Providing** (normal conversation mode)
   - User provides project context, specifications, and relevant code
   - AI reads and acknowledges understanding
2. **Stage 2: Planning** (normal conversation mode, optional)
   - Discuss feature approach and create "Roadmap" (a planning file) with test scenarios
   - Determine work type: domain/business logic vs technical implementation vs presentation/UI
   - AI helps plan but doesn't write code yet
3. **Stage 3: TDD Starts** (transition to TDD mode)
   - User explicitly initiates TDD
   - Create test structure based on specifications
   - **Enter RED phase immediately**
4. **Stage 4: TDD Cycle** (strict TDD phase rules now apply)
   - Follow RED → GREEN → REFACTOR → repeat cycle
   - Continue until all specification scenarios are tested and passing

Stages 1-3 use normal AI assistance. Stage 4 enforces strict TDD discipline as defined below.

### Recognizing AAID TDD Mode

**AAID TDD mode is ACTIVE when:**

- User explicitly says "start TDD", "begin AAID", "use test list", or similar
- User references TDD phases: "RED phase", "GREEN phase", "REFACTOR phase"
- User asks to write a failing test, make a test pass, or refactor with tests green
- Currently in an active TDD cycle that hasn't been completed

**AAID TDD mode is NOT active when:**

- User is simply sharing context, files, or documentation
- User is discussing planning, architecture, or features
- User asks general programming questions
- User explicitly indicates working on something else

### Implementation Categories

When in AAID mode, the workflow applies differently based on implementation category:

- **Domain/Business Logic**: Core business behavior using unit tests with mocks (default focus)
- **Technical Implementation**: Adapters and infrastructure using integration/contract tests
- **Presentation/UI**: Pure visual styling and sensory feedback - NO TDD, validation only

The TDD phases (RED/GREEN/REFACTOR) apply only to Domain and Technical Implementation work:

- **Domain work** uses Feature Roadmaps and unit tests as described in these AAID instructions. These are the *inner* loop; the story's acceptance spec (see "Acceptance tests") is the outer loop
- **Technical Implementation work** uses Technical Roadmaps with tests based on dependency:
  - Integration tests for managed dependencies (your database, cache, queues)
  - Contract tests for unmanaged dependencies (external APIs like Stripe, SendGrid)
- **Presentation/UI work** skips TDD entirely - proceeds directly to implementation with manual validation, visual regression, accessibility audits

If user mentions "adapter", "repository", "controller", "infrastructure" → Technical Implementation
If user mentions "css", "styling", "animation", "visual design", "colors", "spacing" → Presentation/UI (no TDD)
Ask user to clarify if unclear which type of work is being done

### Phase Recognition (When in TDD Mode)

**Priority for determining phase:**

1. Explicit user declaration ("we're in RED phase") overrides all
2. Follow strict sequence: RED → GREEN → REFACTOR → RED (no skipping phases)
3. If unclear which phase, ask: "Which TDD phase are we in?"

### TDD Cycle Phases

**IMPORTANT:** These phases only apply when TDD mode is active. Each phase follows the same structured format: Triggers, Core Principle, Instructions, On Success/Error handling, and Next Phase.

#### 🔴 RED Phase - Write Failing Test

**Triggers:** "write test", "test for", "red", "next test", "red phase"

**Core Principle:** Write only enough test code to fail - no production code without a failing test first. Let tests drive design.

**Instructions:**

1. Write the SMALLEST test that will fail for the next requirement
   - If test list exists: Un-skip the next test and implement its body
   - If single test approach: Write a new test for the next scenario
   - Follow test sequence from Roadmap/specs if provided
   - Start with simplest scenario (usually happy path) for new features
   - Follow ZOMBIES progression: Zero → One → Many is the happy path; after each step, interleave applicable Boundaries, Interface, and Exceptions before moving to the next
   - Compilation/import errors are valid failures
2. Test structure requirements:

   - Use Given/When/Then structure (Gherkin format):
     \`\`\`javascript
     // Given
     [setup code]

     // When
     [action code]

     // Then
     [assertion code]
     \`\`\`

   - Comments exactly as shown: `// Given`, `// When`, `// Then` (optional: `// And`, `// But`)
   - No other test structure comments allowed
   - Test behavior (WHAT), not implementation (HOW)
   - Mock ALL external dependencies (databases, APIs, file systems, network calls)
   - One assertion per test, or tightly related assertions for one behavior
   - No conditionals/loops in tests
   - Test names describe business behavior
   - Tests must run in milliseconds

3. Run test and verify failure
4. Run tests after EVERY code change

**On Success:** Present test and result, then **STOP AND AWAIT USER REVIEW**
**On Error:** If test passes unexpectedly, **STOP** and report (violates TDD, risks false positives)
**Next Phase:** GREEN (mandatory after approval)

#### 🟢 GREEN Phase - Make Test Pass

**Triggers:** "make pass", "implement", "green", "green phase"

**Core Principle:** Write only enough production code to make the failing test pass - nothing more. Let tests drive design, avoid premature optimization.

**Instructions:**

1. Write ABSOLUTE MINIMUM code to pass current test(s)
   - Start with naïve code or hardcoding/faking (e.g., return "Hello")
   - Continue hardcoding until tests force abstraction/generalization
   - When tests "triangulate" (multiple examples pointing to a pattern), generalize
   - NO untested edge cases, validation, or future features
   - Simplified example: Test 1 expects 2+2=4? Return 4. Test 2 expects 3+3=6? Return 6.
     Test 3 expects 1+5=6? Now you need actual addition logic.
2. "Minimum" means: simplest code that passes ALL existing tests
3. Verify ALL tests pass (current + existing)
4. Run tests after EVERY code change

**On Success:** Present implementation, then **STOP AND AWAIT USER REVIEW**
**On Error:** If any test fails, **STOP** and report which ones
**Next Phase:** REFACTOR (mandatory after approval - NEVER skip to next test)

#### 🧼 REFACTOR Phase - Improve Code Quality

**Triggers:** "refactor", "improve", "clean up", "refactor phase"

**Core Principle:** With passing tests as safety net, improve code structure and update tests if design changes. No premature optimization.

**Instructions:**

1. Evaluate for improvements (always complete evaluation):
   - Code quality: modularity, abstraction, cohesion, separation of concerns, readability
   - Prefer pure functions. Isolate side effects at boundaries (I/O, DB, network)
   - Remove duplication (DRY), improve naming, simplify logic
   - If no improvements needed, state "No refactoring needed" explicitly
   - If improvements found, suggest them and ask user approval before implementing
2. When refactoring changes the design/API:
   - Update tests to use the new design
   - Remove old code that only exists to keep old tests passing
   - Tests should test current behavior, **not preserve legacy APIs to keep tests green** (unless the user explicitly requests it)
3. Add non-behavioral supporting code (ONLY in this phase):
   - Logging, performance optimizations, error messages
   - Comments for complex algorithms, type definitions
4. Keep all tests passing throughout
   - Run tests after EVERY code change

**On Success:** Present outcome (even if "no refactoring needed"), then **STOP AND AWAIT USER REVIEW**
**On Error:** If any test breaks, **STOP** and report what broke
**Next Phase:** After approval, automatically continue to RED for next test if more specs/scenarios remain. If all covered, feature complete.

### Starting TDD

When user initiates TDD mode:

User chooses approach (ask which they prefer if not clear):

1. **Test List**: Create list of unimplemented tests (skipped - e.g. `it.skip`) based on Roadmap plan file (if available)
2. **Single Test**: Start with one single unimplemented empty/skipped test for simplest scenario based on Roadmap plan file (if available)

In all cases:

- Order tests following the ZOMBIES progression (James Grenning): Zero → One → Many is the happy path; after each step, interleave applicable Boundaries, Interface, and Exceptions before moving to the next. Keep both scenarios and solutions Simple.
- Only create test structure in Stage 3 - RED phase implements
- Each test gets complete RED→GREEN→REFACTOR cycle
- Never implement multiple tests at once

### Critical Rules

- **ALWAYS run tests after every code change** - check codebase test configuration if you don't know how
- **NEVER skip REFACTOR phase** - even if no changes needed, must explicitly complete it
- **ALWAYS STOP AND AWAIT USER REVIEW between phases** - this is mandatory
- State persists between messages - remember current phase and test progress
- Explicit user instructions override AAID workflow rules

#### The Three Laws of TDD

1. Write no production code without a failing test
2. Write only enough test code to fail
3. Write only enough production code to pass
