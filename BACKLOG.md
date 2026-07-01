# Sheephead Engine — Backlog

A living backlog for building a configurable Sheephead engine in pure Dart, ending
with a terminal-playable game (King 9 style) for the **4-player Spitzer** variant.

## Epic 0 — Scaffolding (the pipeline before the product)

- [x] **0.1** Create the workspace repo with `packages/sheephead_engine` and
      `packages/sheephead_cli`. One trivial passing test in each. *Done when:* `dart test`
      is green in both.
- [x] **0.2** Wire CI (GitHub Actions): `dart analyze`, `dart format --set-exit-if-changed`,
      `dart test`. *Done when:* a PR runs all three and blocks on failure.
- [x] **0.3** Add `mutation_test` as a dev dependency and an on-demand local script
      (`tool/mutation.sh`) that mutation-tests a given list of files. *Done when:* a
      deliberately weak test (no assertion) shows a surviving mutation in the report.
      (Revised from the original CI-job plan — mutation testing is too slow for the
      push/CI gate, so it's deliberately local-only and on-demand; see `CLAUDE.md`.)
- [x] **0.4** Lint config (`package:lints` or stricter). Pin Dart SDK. *Done when:* analyze
      is clean with the strict rule set.

## Epic 1 — Cards, deck, and trump (all config-driven)

- [x] **1.1** `Suit` and `Rank` enums; `Card` immutable value object with value equality.
      *Done when:* `Card(clubs, queen) == Card(clubs, queen)` and they hash equal.
- [ ] **1.2** `DeckComposition` in `GameConfig`: build a full 32-card deck OR the Spitzer
      26-card deck (remove 7♣ 7♠ 7♥ 8♣ 8♠ 8♥; keep 7♦ 8♦ as diamonds/trump). *Done when:*
      Spitzer deck has exactly 26 cards and contains 7♦ + 8♦ but not 7♣/8♣ etc.
- [ ] **1.3** `TrumpOrder` strategy: a comparator over trump cards. Provide `standard`
      and `spitzer` (7♦ ranked second, immediately behind Q♣). *Done when:* in spitzer
      order, 7♦ beats every trump except Q♣.
- [ ] **1.4** `isTrump(card, config)` and full power-ranking of any two cards for trick
      resolution. *Done when:* a parameterized table of (cardA, cardB, leadSuit) → winner
      passes for both variants.

## Epic 2 — Deal (and the engine's command/event contract)

> This epic introduces the engine's public contract, which every later epic (picking,
> bury, steal, trick play) reuses: clients submit a sealed `Command`, dispatched via an
> exhaustive `switch`; the engine returns a sealed `CommandResult` — `Accepted()` or
> `Rejected(reason)` — never an exception, across this boundary. Internally, `Event`s fold
> through a pure `apply(state, event) -> state` reducer so `MasterGameState` is always
> *derived from* its event history, not separately mutated — but `Event` is engine-private.
> Clients observe changes via `GameObserver.onChanged()` and read state via
> `GameSession.viewFor(PlayerId)`. A CLI-driven human and an AI (Epic 12) are both just
> command-producers against this same contract — Deal is simply the first command to flow
> through it. See `CLAUDE.md`'s engine-contract invariant.

- [ ] **2.1** Outside-in: write a failing test that submits a `Deal` command (a config +
      a seeded shuffler) and asserts on the resulting `PlayerView`s — hand sizes, blind
      size, all cards accounted for, no duplicates — via the `CommandResult`, never by
      reaching into engine internals directly. *Done when:* the test exists and fails
      (most likely on missing types at first, since `Command`/`Event`/`CommandResult`
      don't exist yet).
- [ ] **2.2** Minimal `Command` / `Event` / `CommandResult` sealed-class skeleton — just
      enough surface (`Deal`, `HandDealt`, `Accepted`/`Rejected`) for 2.1 to compile.
      *Done when:* 2.1 compiles and fails on an assertion, not on a missing type.
- [ ] **2.3** `Shuffler` wrapping an injected `Random`. *Done when:* same seed → same order;
      different seed → (almost always) different order.
- [ ] **2.4** `Deal` command handler — `(state, Deal) -> Rejected | [HandDealt]` — sized
      from config, reusing Epic 1.2's `DeckComposition`. *Done when:* a 4-player Spitzer
      deal yields four 6-card hands and a 2-card blind, all 26 cards accounted for, no
      duplicates.
- [ ] **2.5** `apply(state, HandDealt)` reducer + `deriveView(state, playerId)`, enough for
      2.1's `PlayerView` assertions to pass. *Done when:* 2.1 is green.
- [ ] **2.6** Config validation: deck size must equal `players * handSize + blindSize`.
      *Done when:* an inconsistent config produces a `Rejected` `CommandResult` with a
      typed reason at `Deal` time (not a thrown exception, per the error-shape decision).

## Epic 3 — Game state and hidden information

- [ ] **3.1** `MasterGameState` — server/engine-only, full information.
- [ ] **3.2** `PlayerView` — derived per player: own cards in full, others as counts,
      table cards visible, blind hidden unless rules say otherwise. *Done when:* a player's
      view never contains another player's concealed cards (assert at the type/serialization
      boundary, not just in UI).
- [ ] **3.3** Pure `deriveView(master, playerId)` function. *Done when:* a mutation that
      leaks a hidden card is caught by a test.

## Epic 4 — Picking phase + all-pass resolution

- [ ] **4.1** Pick/pass turn order starting left of dealer. *Done when:* the prompt advances
      correctly and stops on the first pick.

> All-pass resolution is a richer config axis than "doubles vs leaster" — known real-world
> resolutions include at least: (1) **misdeal-counts** — no score change, but the hand still
> consumes a slot in the `Game`'s fixed hand budget, next dealer deals; (2)
> **redeal-doesn't-count** — same dealer redeals, the failed deal does *not* consume a slot,
> only the eventual resolved deal does; (3) **Leaster** — the hand is played out under a
> different win condition (least points among trick-takers, or least points among all
> players including those with zero tricks), with a configurable tie-break that itself
> sometimes falls back to (1)'s behavior; (4) **dealer-must-pick** — removes the all-pass
> branch entirely by forcing a pick, regardless of hand quality; (5) **Doubles** — same as
> (2) (redeal, doesn't consume a slot), but additionally queues a forward-looking scoring
> obligation on however many *future, counted* hands it takes to spend, escalating on
> repeated all-passes. Each strategy should expose two independent properties rather than
> assume one implies the other: **does this hand consume a counted slot in the `Game`'s
> fixed budget**, and **what is the scoring effect** (none / Leaster settlement / queued
> future multiplier). Doubles is the only one of the five with a cross-hand carry-forward
> obligation — see 4.4.

- [ ] **4.2** `AllPassResolution` strategy interface (config-selectable), each strategy
      exposing "consumes a counted hand slot?" and "scoring effect" independently, covering
      at least misdeal-counts, redeal-doesn't-count, Leaster (with a configurable tie-break),
      dealer-must-pick, and Doubles. *Done when:* each of the five behaves per the note above
      and is swappable via `GameConfig` alone.
- [ ] **4.3** Escalating doubles tracker: pass again → next *two* hands doubled, and so on.
      Same dealer redeals *while the misdeal streak continues*; the moment any hand has a
      picker, dealer rotation resumes normally and the queued multiplier credit travels by
      **hand-count, not dealer identity** (confirmed design intent — a dealer is never locked
      in place to personally clear the credit backlog; see design discussion). *Done when:* a
      sequence of all-pass hands produces the documented escalation, redeal-during-streak is
      honored, and a credit queued during one dealer's deal is correctly spent on a
      later, normally-rotated dealer's hand.
- [ ] **4.4** *(open question)* Doubles' queued multiplier credit may not be fully spent when
      a `Game` reaches its final hand. Resolution policy undecided — candidates: forfeit the
      unspent credit, or carry it forward to a subsequent `Game` via the (parked) `Session`
      concept. See `Notes / parking lot`.

## Epic 5 — Bury

- [ ] **5.1** Picker takes the blind and buries `buryCount` cards (config). *Done when:*
      picker's hand returns to the correct size and buried cards leave play but are recorded
      for scoring.
- [ ] **5.2** Bury legality rules (e.g., restrictions per config). *Done when:* an illegal
      bury is rejected with a typed error.

## Epic 6 — Partner determination (Jack of Diamonds calling)

> A previously-undocumented core mechanic: unless the picker goes alone, their partner is
> whoever holds the J♦ — unknown to the table until revealed by play. This determines team
> membership for scoring (Epic 9) and gates whether the blind can be stolen at all (Epic 7).

- [ ] **6.1** Default partnership: if the picker neither chops nor buries J♦, their partner
      is whoever holds J♦, resolved for scoring purposes (Epic 9) — not revealed to other
      players during play unless/until the card itself is played, per the hidden-information
      invariant. *Done when:* a non-chopped, non-J♦-buried hand resolves the correct partner
      at settlement time.
- [ ] **6.2** "Chop" declaration: the picker may declare chop at bury time, declining the
      J♦ partnership and going alone. *Done when:* a chopped hand scores as picker-alone,
      ignoring whoever holds J♦.
- [ ] **6.3** Illegal chop: a picker holding J♦ themselves may not declare chop (no partner
      exists to cut off; the announcement would mislead the table into believing one exists
      elsewhere). *Done when:* attempting to chop while holding J♦ is rejected with a typed
      reason.
- [ ] **6.4** Mandatory bury announcement: burying J♦ must be announced at bury time (it
      also removes any possible partner, since the card leaves every active hand). *Done
      when:* burying J♦ without the announcement flag is rejected; with it, the bury
      succeeds and is recorded as partner-less.
- [ ] **6.5** *(open question)* Does an announced J♦ bury block the steal-the-blind offer
      the same way an explicit chop does (Epic 7)? Not yet decided — flag for the maintainer.

## Epic 7 — Steal the blind

> Offered only to players who never got a chance to pick — i.e., whoever comes after the
> picker in the pick/pass turn order (left of dealer → ... → dealer last); if the dealer
> picked, no one is offered a steal at all. Never offered if the picker declared chop
> (Epic 6.2) — see Epic 6.5 for the still-open question of whether an announced J♦ bury
> also blocks it. Offered only after the bury concludes, in turn order starting left of the
> picker and ending at the dealer; default is decline (no prompt friction — skip via a
> single keypress); the first player to accept gets it and no one else is asked. A picker
> who secretly holds J♦ (and so cannot legally chop, per 6.3) has no way to block the offer
> — stealing proceeds normally in that case; this is an accepted asymmetry in the house
> rules, not a bug. Stealing = going alone; the stealer does not see the blind.

- [ ] **7.1** `StealDeclaration` window: opens once the bury concludes (and only if the
      picker didn't chop), offered in turn order to eligible players only (those after the
      picker, up to and including the dealer), first acceptance wins and ends the offering;
      default is decline. *Done when:* a sequence of declines followed by one acceptance
      grants the steal to exactly that player and stops offering the rest; a chopped hand
      never opens the window at all.
- [ ] **7.2** Eligibility rule: only players who never got a chance to pick (those whose
      pick/pass turn would have come after the picker) are offered a steal — players who
      already passed are not re-offered. *Done when:* if the dealer is the picker, no one
      is offered; otherwise exactly the players after the picker through the dealer are
      offered, in that order.
- [ ] **7.3** Steal sets the stealer to "alone" and emits a notification event before the
      first lead. *Done when:* defenders' views show the steal before any card is played.
- [ ] **7.4** Stealer never receives blind contents in their view. *Done when:* a test
      asserts the blind is absent from the stealer's `PlayerView`.
- [ ] **7.5** Feature flag in config: `stealTheBlind: on/off`. *Done when:* with it off,
      the declaration option never appears.

## Epic 8 — Trick play

- [ ] **8.1** Legal-move validation: follow led suit; trump rules; using the variant's
      trump definition. *Done when:* illegal plays rejected, legal plays accepted, across
      both variants.
- [ ] **8.2** Trick-winner resolution using the trump comparator + lead suit. *Done when:*
      table-driven cases pass, including 7♦ winning under spitzer order.
- [ ] **8.3** Play a full hand of tricks; collect won cards per player/team. *Done when:*
      all tricks resolve and every card ends in exactly one trick pile.

## Epic 9 — Scoring (config-driven)

- [ ] **9.1** Point values per card; sum tricks; include buried cards for the picker side.
      *Done when:* total points across both sides equal the deck's fixed point total.
- [ ] **9.2** Determine picker side vs defenders, accounting for alone (chop), steal, and
      partner-via-J♦ (Epic 6). *Done when:* win/loss thresholds resolve correctly for
      alone, partnered, and stolen cases.
- [ ] **9.3** Picker-no-trick penalty: if picker takes zero tricks, apply configurable
      multiplier (default ~4× base). *Done when:* toggling the multiplier changes the
      settlement as specified.
- [ ] **9.4** Apply doubles multiplier(s) from Epic 4 to the hand's settlement. *Done when:*
      a doubled hand pays out at the right multiple.
- [ ] **9.5** "Cut card triggers doubles" optional rule as an injected hook. *Done when:*
      with the rule on and the trigger card cut, the *next* hand is flagged doubled.

## Epic 10 — Game (bounded multi-hand session)

> A `Game` is the unit results are compared on, especially for rule-impact experiments and
> tournament play: a fixed number of rounds, agreed before play begins. A "round" is one
> full trip around the table — every player deals exactly once — so
> `roundsPerGame * playerCount = handsPerGame`.

- [ ] **10.1** `Game` requires a round count at creation; derives total hands as
      `roundsPerGame * playerCount`. *Done when:* constructing a `Game` without a round
      count is a compile-time error, and a 4-player Game with `roundsPerGame: 20` reports
      80 total hands.
- [ ] **10.2** `Game` is immutable once created: no operation extends or shortens its round
      count afterward. *Done when:* there is no API that mutates a `Game`'s length —
      wanting more play means constructing a new `Game`, not extending the current one.
- [ ] **10.3** `Game` aggregates the running tally and doubles/penalty escalation state
      across its hands (carrying forward what Epic 4's escalation tracker and Epic 9's
      scoring produce, hand to hand). *Done when:* playing every hand in a `Game` produces
      one final settlement reflecting every hand's contribution.
- [ ] **10.4** `Game` reports completion once `handsPerGame` hands have been played, not
      before or after. *Done when:* a `Game` constructed with N rounds halts at exactly
      `N * playerCount` hands.

## Epic 11 — Terminal play (MVP MILESTONE 🎯)

> Goal: sit down and play a full 4-player Spitzer `Game` in the terminal, one human + three
> AI, the way you play King 9 — including your house rules.

- [ ] **11.1** Render a `PlayerView` to the terminal (hand, table, scores). *Done when:*
      a dealt hand prints legibly, cards numbered for selection (no trump grouping/sorting
      required for v1 — selection is by number, not by suit/trump knowledge).
- [ ] **11.2** Prompt the human for pick/pass, bury, steal, and each card play; validate
      against engine legality. *Done when:* illegal input is re-prompted, never crashes.
- [ ] **11.3** Drive a complete hand end-to-end (deal → pick → bury → [steal] → tricks →
      score) against placeholder AI. *Done when:* one full Spitzer hand plays to settlement
      in the terminal.
- [ ] **11.4** Play a full `Game` (the round count agreed at the table) hand-by-hand in the
      terminal, carrying tally and doubles/penalty state via the `Game` aggregate from
      Epic 10, and report the final settlement once the agreed rounds are complete.
      *Done when:* a `Game` constructed with N rounds plays to completion and reports a
      final result without the player having to decide when to stop.

**🎯 Reaching 11.4 is your first real, playable milestone.**

## Epic 12 — First AI + the benchmark harness

> The AI is an **external consumer** of the engine's command/query contract — the same one
> a human-driven CLI uses — not an engine internal. It reads a `PlayerView` and submits the
> same commands (pick/pass, bury, steal, play) a human would, with no privileged access to
> engine internals. This is what makes "every seat is an AI" trivial for large-scale
> rule-impact experiments.

- [ ] **12.1** `SheepheadAi` interface: `decidePick`, `decideBury`, `decidePlay`,
      (later) `declareSteal`. Separate decision trees for picker-role vs defender-role.
      *Done when:* the terminal game runs with an AI implementing the interface.
- [ ] **12.2** `RandomAi` — 50/50 legal choices. *Done when:* it can fill all three
      opponent seats and complete hands.
- [ ] **12.3** Headless simulation runner: play N `Game`s among given AIs with a seeded
      RNG, collect win rates. *Done when:* 4× `RandomAi` over a large N converges to
      near-equal win rates (your control baseline), and the runner can compare two
      `GameConfig` variants (e.g., a rule toggled on vs off) over large N to measure the
      rule's impact.
- [ ] **12.4** First rules-based decision (e.g., "Keep Stopper" for defenders) behind the
      `SheepheadAi` interface, with an `explain()` hint string. *Done when:* the rules AI
      beats the random baseline by a statistically clear margin in the sim, AND the same
      rule object can emit a coaching hint in the terminal.

## Epic 13 — Terminal CLI experience details

> Captured from CLI-design discussion, ahead of full implementation in Epic 11.

- [ ] **13.1** Session config is hardcoded for v1 (a single `GameConfig`, fixed round
      count) — no file loading yet. *Done when:* the CLI starts a `Game` with no
      user-supplied configuration at all.
- [ ] **13.2** *(deferred, not v1)* Load `GameConfig` from a JSON/YAML file, selectable via
      a CLI flag, so more than one config can be used. Parked until after the MVP milestone.
- [ ] **13.3** Launch goes straight into hand one — no menu/lobby screen.
- [ ] **13.4** Card selection by number: the hand is listed with each card numbered; the
      human types a number to play a card, or comma-separated numbers to bury multiple.
      *Done when:* selection works without needing sorted/grouped trump display.
- [ ] **13.5** Illegal selections are rejected with a re-prompt and explanation, rather
      than filtering the displayed list down to only-legal cards. *Done when:* an illegal
      pick shows the rejection reason and re-prompts against the same full hand listing.
- [ ] **13.6** No coaching/hints in the CLI MVP. Parked for later, alongside Epic 12.4's
      `explain()` hint string.
- [ ] **13.7** End-of-hand screen shows both this hand's point swing and the cumulative
      running tally across the `Game`. Settlement is zero-sum across players.
- [ ] **13.8** After each trick completes, hold the screen showing all four played
      cards and who won, waiting for the human to press Enter before advancing to the
      next lead. The engine has already moved on — this is a display pause in the UI,
      not an engine pause. AI players do not pause. *Done when:* the trick result is
      visible after every trick and input is required before the next lead prompt
      appears.
- [ ] **13.9** Advance to the next hand via Enter after the settlement screen (not
      literal spacebar/raw-mode input, to avoid needing raw terminal mode in Dart).
      *Done when:* pressing Enter after a settlement screen starts the next hand.
- [ ] **13.10** When the `Game` completes (Epic 10.4), the CLI prints the final settlement
      and exits — no offer to start a new `Game` automatically.

---

## Notes / parking lot

### Per-player UI preferences (tabled, not in scope yet)

Distinct from `GameConfig` (which governs rules for all players equally), each
player has personal display preferences that affect only their own view. Two
categories:

**Cosmetic / pacing:**
- Delay between events (0 = instant, N seconds = animated); used when events
  arrive faster than the player wants to read them.
- Manual advance at trick-end (press Enter) vs. auto-advance after a fixed
  delay.
- Card sort order, color scheme, font size (future app concern).

**Informational overlays** (some can be locked off by the host for fairness):
- Running point totals per player/team after each trick.
- Trump counter: how many trump have been played / how many remain.
- Boss-card indicator: which card currently wins if led.
- AI coaching hints: "this card is likely to take the trick" etc.
- Partner-reveal hints (who probably holds J♦ based on play so far).

**Host-level gating:** A game host may disable specific overlays globally
(e.g., no coaching hints in a competitive game) regardless of individual
preference. Individual preferences apply only within what the host permits.

Design note: these preferences live outside `GameConfig` and outside the
engine entirely. The CLI/app layer owns them. The engine's `PlayerView`
provides the raw data; the UI layer decides what derived information to surface
and how.

### Display pacing / view buffer (tabled)

When `GameObserver.onChanged()` fires faster than the UI wants to show each
state (e.g., three AI plays in rapid succession), the presenter needs an
internal buffer of `PlayerView` snapshots — one captured per `onChanged()` call
— that it replays at the player's configured rate rather than rendering them all
at once. The trick-end manual-advance (BACKLOG 13.8) is the simplest form of
this; a timed delay between snapshots is a generalization. Design this when
implementing 13.8.

- 5-player online with the dealer sitting out → a `seating`/`dealerPlays` config concern;
  design `GameConfig` so this is data, not a new code path.
- Replay/analysis tools fall out of `MasterGameState` history "for free" later.
- Keep a `variants/` folder of named `GameConfig` builders: `spitzer4()`,
  `houseRulesGaylord()`, etc. Your community's rules are just another entry.
- `PlayerProfile`: cross-game opponent modeling (e.g., "this player picks aggressively"),
  derived from a completed `Game`'s event history but persisted *outside* the engine
  (CLI/server territory), not an engine concept. Far-future idea, not blocking current work.
- `Session`: chains multiple back-to-back `Game`s for a casual table that wants to keep
  playing past one agreed round count, optionally carrying cumulative tally across
  `Game`s. Explicitly outside the engine's `Game` abstraction, which stays fixed-length
  and immutable for comparability. Not designed yet — parked.
