# Sheephead — Project Context

Seed context for a long-running build. This file is the durable "what and why."
Rules, commands, and architecture invariants are canonical in `CLAUDE.md` —
this file doesn't restate them, only the product/historical context behind
them. The live source of truth for *where the build is* is the git repo and
`BACKLOG.md`, not this file.

- **Repo:** https://github.com/justinleebehnke/sheephead-dart
- **Site:** https://sheephead.club (coming-soon page live)
- **Stack:** Dart workspace (Dart 3.12.2 / Flutter 3.44.2 at time of writing)

---

## 1. Product vision

A "chess.com for Sheephead": **learn, compete, and belong.** Sheephead is a
regional card game (Wisconsin/Minnesota German heartland) that is hard
to learn and poorly served online. The platform aims to fix that.

Core pillars:

- **Teach the next generation.** The strongest emotional hook: older players want
  to pass the game on, but it's brutal to learn at a table. Structured lessons,
  practice hands, and an AI that explains its reasoning make that possible.
- **Offline solo training** against a convincing rules-based AI (a must-have,
  modeled on King 9's training experience). Because this must work with no
  network, the engine has to run **on-device** — which is why the engine is in
  Dart, shared by the Flutter app.
- **Online multiplayer**, mobile-first (Flutter: web, iOS, Android). Voice/video
  is intentionally offloaded to external tools (phone call / Google Meet),
  optional, not built in.
- **Highly configurable rules.** Sheephead is extremely customizable; each group
  has house rules. Configurability is a first-class design concern, not an
  afterthought.

Monetization (deferred, not built early):

- Freemium — free core play; premium training, rule customization, tournaments.
- A "Buy Me a Burger" tip jar is already on the site.
- **The app never touches money.** Players may optionally display a Venmo handle
  to settle up offline among themselves. Taking a cut of money changing hands
  would be gambling under Minnesota law and is explicitly out of scope. The app
  is a scorekeeper, not a money mover.

---

## 2. The primary variant: 4-player Spitzer

The full rule set (deck, trump order, steal-the-blind, doubles, penalties) is
the project's default `GameConfig` and is documented canonically in
`CLAUDE.md`. The context worth keeping here: this is the **maintainer's own
table's house rules**, not "canonical" Sheephead — Sheephead is extremely
regional and customizable, so configurability is a first-class design concern
rather than an afterthought. Future config axes (5-player with the dealer
sitting out, leaster, crack/recrack doublers, bury legality) are tracked in
`BACKLOG.md`'s parking lot.

---

## 3. Architecture

**One engine, many consumers.** The Sheephead brain is a pure-Dart package that
knows nothing about UI, I/O, or networking. It is imported by the Flutter app
(for offline solo play), a Dart server (for multiplayer), and a CLI (for fast
testing) alike. Write the rules once; run them everywhere.

The workspace layout, the `cli → engine` dependency rule, Dart package
conventions, and the architecture invariants (config as domain model, injected
seeded RNG, hidden-information boundary) are canonical in `CLAUDE.md`. One
piece of history behind the hidden-information invariant worth keeping: the
first prototype's flaw was that clients knew everything, so a savvy player
could read opponents' cards. The fix lives in the view-derivation layer, not
the UI — that's *why* it's a hard invariant now, not a style preference.

AI design (interface, rule-objects-that-explain-themselves, `RandomAi`
benchmark) is canonical in `CLAUDE.md`. One future direction not yet in scope:
once enough real hands are logged, study how winners make edge decisions and
feed that back into the rules — players could flag hands where the AI chose
wrong, building a supervised dataset over time.

---

## 4. Working discipline (Dave Farley / trunk-based)

Day-to-day rules — TDD outside-in, the format/analyze/test gates, the
pre-push hook, mutation testing, and the trunk-based git/PR workflow — are
canonical in `CLAUDE.md`. The values behind them: slow and steady, never long
debugging sessions, explicit dependency injection, minimal reliance on
framework magic, a codebase to enjoy for decades.

Contributor PRs that add/change logic should include mutation evidence (see
`CONTRIBUTING.md` + PR template).

---

## 5. Current status

- **Epic 0 (project infrastructure): COMPLETE.**
  - Pub workspace scaffold with `sheephead_engine` + `sheephead_cli`, green tests.
  - CI on `main`; strict pre-push gate; trunk-based flow with contributor gating;
    on-demand mutation testing wired up.
- **Next up: Story 1.1 — the `Card` value object** (suit + rank, value equality
  and hashing). Deliberately *does not* know whether it is trump — trump-ness
  depends on `GameConfig` (standard vs Spitzer), so it stays out of `Card`.

See `BACKLOG.md` in the repo for the full story breakdown through terminal play.