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

## Epic 2 — Deal

- [ ] **2.1** `Shuffler` wrapping an injected `Random`. *Done when:* same seed → same order;
      different seed → (almost always) different order.
- [ ] **2.2** `deal(config, shuffler)` → N hands + blind, sized from config. *Done when:*
      4-player Spitzer yields four 6-card hands and a 2-card blind, all 26 cards accounted
      for, no duplicates.
- [ ] **2.3** Config validation: deck size must equal `players * handSize + blindSize`.
      *Done when:* an inconsistent config throws a clear, typed error at construction.

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

## Epic 6 — Steal the blind

> Timing per your house rules: a player may *declare intent* to steal before the picker
> buries; the declaration must be locked the moment the picker buries, so all players are
> notified before the first card is led. Stealing = going alone. The stealer does **not**
> see the blind.

- [ ] **6.1** `StealDeclaration` window state machine: open during picking/bury, locked on
      bury. *Done when:* attempting to declare after the lock is rejected.
- [ ] **6.2** Steal sets the stealer to "alone" and emits a notification event before the
      first lead. *Done when:* defenders' views show the steal before any card is played.
- [ ] **6.3** Stealer never receives blind contents in their view. *Done when:* a test
      asserts the blind is absent from the stealer's `PlayerView`.
- [ ] **6.4** Feature flag in config: `stealTheBlind: on/off`. *Done when:* with it off,
      the declaration option never appears.

## Epic 7 — Trick play

- [ ] **7.1** Legal-move validation: follow led suit; trump rules; using the variant's
      trump definition. *Done when:* illegal plays rejected, legal plays accepted, across
      both variants.
- [ ] **7.2** Trick-winner resolution using the trump comparator + lead suit. *Done when:*
      table-driven cases pass, including 7♦ winning under spitzer order.
- [ ] **7.3** Play a full hand of tricks; collect won cards per player/team. *Done when:*
      all tricks resolve and every card ends in exactly one trick pile.

## Epic 8 — Scoring (config-driven)

- [ ] **8.1** Point values per card; sum tricks; include buried cards for the picker side.
      *Done when:* total points across both sides equal the deck's fixed point total.
- [ ] **8.2** Determine picker side vs defenders (account for "alone"/steal). *Done when:*
      win/loss thresholds resolve correctly for alone and partnered cases.
- [ ] **8.3** Picker-no-trick penalty: if picker takes zero tricks, apply configurable
      multiplier (default ~4× base). *Done when:* toggling the multiplier changes the
      settlement as specified.
- [ ] **8.4** Apply doubles multiplier(s) from Epic 4 to the hand's settlement. *Done when:*
      a doubled hand pays out at the right multiple.
- [ ] **8.5** "Cut card triggers doubles" optional rule as an injected hook. *Done when:*
      with the rule on and the trigger card cut, the *next* hand is flagged doubled.

## Epic 9 — Game (bounded multi-hand session)

> A `Game` is the unit results are compared on, especially for rule-impact experiments and
> tournament play: a fixed number of rounds, agreed before play begins. A "round" is one
> full trip around the table — every player deals exactly once — so
> `roundsPerGame * playerCount = handsPerGame`.

- [ ] **9.1** `Game` requires a round count at creation; derives total hands as
      `roundsPerGame * playerCount`. *Done when:* constructing a `Game` without a round
      count is a compile-time error, and a 4-player Game with `roundsPerGame: 20` reports
      80 total hands.
- [ ] **9.2** `Game` is immutable once created: no operation extends or shortens its round
      count afterward. *Done when:* there is no API that mutates a `Game`'s length —
      wanting more play means constructing a new `Game`, not extending the current one.
- [ ] **9.3** `Game` aggregates the running tally and doubles/penalty escalation state
      across its hands (carrying forward what Epic 4's escalation tracker and Epic 8's
      scoring produce, hand to hand). *Done when:* playing every hand in a `Game` produces
      one final settlement reflecting every hand's contribution.
- [ ] **9.4** `Game` reports completion once `handsPerGame` hands have been played, not
      before or after. *Done when:* a `Game` constructed with N rounds halts at exactly
      `N * playerCount` hands.

## Epic 10 — Terminal play (MVP MILESTONE 🎯)

> Goal: sit down and play a full 4-player Spitzer `Game` in the terminal, one human + three
> AI, the way you play King 9 — including your house rules.

- [ ] **10.1** Render a `PlayerView` to the terminal (hand, table, scores). *Done when:*
      a dealt hand prints legibly with trump grouped/sorted.
- [ ] **10.2** Prompt the human for pick/pass, bury, steal, and each card play; validate
      against engine legality. *Done when:* illegal input is re-prompted, never crashes.
- [ ] **10.3** Drive a complete hand end-to-end (deal → pick → bury → [steal] → tricks →
      score) against placeholder AI. *Done when:* one full Spitzer hand plays to settlement
      in the terminal.
- [ ] **10.4** Play a full `Game` (the round count agreed at the table) hand-by-hand in the
      terminal, carrying tally and doubles/penalty state via the `Game` aggregate from
      Epic 9, and report the final settlement once the agreed rounds are complete.
      *Done when:* a `Game` constructed with N rounds plays to completion and reports a
      final result without the player having to decide when to stop.

**🎯 Reaching 10.4 is your first real, playable milestone.**

## Epic 11 — First AI + the benchmark harness

> The AI is an **external consumer** of the engine's command/query contract — the same one
> a human-driven CLI uses — not an engine internal. It reads a `PlayerView` and submits the
> same commands (pick/pass, bury, steal, play) a human would, with no privileged access to
> engine internals. This is what makes "every seat is an AI" trivial for large-scale
> rule-impact experiments.

- [ ] **11.1** `SheepheadAi` interface: `decidePick`, `decideBury`, `decidePlay`,
      (later) `declareSteal`. Separate decision trees for picker-role vs defender-role.
      *Done when:* the terminal game runs with an AI implementing the interface.
- [ ] **11.2** `RandomAi` — 50/50 legal choices. *Done when:* it can fill all three
      opponent seats and complete hands.
- [ ] **11.3** Headless simulation runner: play N `Game`s among given AIs with a seeded
      RNG, collect win rates. *Done when:* 4× `RandomAi` over a large N converges to
      near-equal win rates (your control baseline), and the runner can compare two
      `GameConfig` variants (e.g., a rule toggled on vs off) over large N to measure the
      rule's impact.
- [ ] **11.4** First rules-based decision (e.g., "Keep Stopper" for defenders) behind the
      `SheepheadAi` interface, with an `explain()` hint string. *Done when:* the rules AI
      beats the random baseline by a statistically clear margin in the sim, AND the same
      rule object can emit a coaching hint in the terminal.

---

## Notes / parking lot

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
  