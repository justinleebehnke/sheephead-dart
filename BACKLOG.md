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

- [ ] **1.1** `Suit` and `Rank` enums; `Card` immutable value object with value equality.
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
- [ ] **4.2** All-pass resolution as an injected strategy: `DoublesOnPass` vs `Leaster`
      (config-selectable). *Done when:* with `DoublesOnPass`, an all-pass hand sets the
      next hand's multiplier.
- [ ] **4.3** Escalating doubles tracker: pass again → next *two* hands doubled, and so on;
      same dealer redeals (configurable). *Done when:* a sequence of all-pass hands produces
      the documented escalation and the redeal flag is honored.

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

## Epic 9 — Terminal play (MVP MILESTONE 🎯)

> Goal: sit down and play a full 4-player Spitzer hand in the terminal, one human + three
> AI, the way you play King 9 — including your house rules.

- [ ] **9.1** Render a `PlayerView` to the terminal (hand, table, scores). *Done when:*
      a dealt hand prints legibly with trump grouped/sorted.
- [ ] **9.2** Prompt the human for pick/pass, bury, steal, and each card play; validate
      against engine legality. *Done when:* illegal input is re-prompted, never crashes.
- [ ] **9.3** Drive a complete hand end-to-end (deal → pick → bury → [steal] → tricks →
      score) against placeholder AI. *Done when:* one full Spitzer hand plays to settlement
      in the terminal.
- [ ] **9.4** Hand loop: play consecutive hands, carry the running tally and any
      doubles/penalty state between them. *Done when:* you can play a short session and quit.

**🎯 Reaching 9.4 is your first real, playable milestone.**

## Epic 10 — First AI + the benchmark harness

- [ ] **10.1** `SheepheadAi` interface: `decidePick`, `decideBury`, `decidePlay`,
      (later) `declareSteal`. Separate decision trees for picker-role vs defender-role.
      *Done when:* the terminal game runs with an AI implementing the interface.
- [ ] **10.2** `RandomAi` — 50/50 legal choices. *Done when:* it can fill all three
      opponent seats and complete hands.
- [ ] **10.3** Headless simulation runner: play N hands among given AIs with a seeded RNG,
      collect win rates. *Done when:* 4× `RandomAi` over a large N converges to near-equal
      win rates (your control baseline).
- [ ] **10.4** First rules-based decision (e.g., "Keep Stopper" for defenders) behind the
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
  