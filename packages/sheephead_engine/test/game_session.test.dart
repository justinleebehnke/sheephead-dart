import 'dart:math';

import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:sheephead_engine/src/master_game_state.dart';
import 'package:test/test.dart';

void main() {
  group('SheepheadGameSession — initial deal', () {
    late SheepheadGameSession session;
    final playerIds = List.generate(4, PlayerId.new);

    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
    });

    test('each player receives 6 cards', () {
      for (final id in playerIds) {
        expect(session.viewFor(id).hand, hasLength(6));
      }
    });

    test('no card appears in more than one hand', () {
      final allCards = playerIds
          .expand((id) => session.viewFor(id).hand)
          .toList();
      expect(allCards.toSet(), hasLength(allCards.length));
    });

    test('all hand cards are from the Spitzer deck', () {
      final spitzerDeck = DeckComposition.spitzer().cards.toSet();
      final allHandCards = playerIds.expand((id) => session.viewFor(id).hand);
      expect(allHandCards, everyElement(isIn(spitzerDeck)));
    });

    test('all views show PickPhaseViewDto', () {
      for (final id in playerIds) {
        expect(session.viewFor(id).phase, isA<PickPhaseViewDto>());
      }
    });

    test('exactly one player is first to act', () {
      final acting = playerIds
          .where((id) => session.viewFor(id).isMyTurnToAct)
          .toList();
      expect(acting, hasLength(1));
    });

    test('first to act is left of dealer', () {
      final dealer = playerIds.firstWhere(
        (id) => session.viewFor(id).isIDealer,
      );
      final firstToAct = playerIds.firstWhere(
        (id) => session.viewFor(id).isMyTurnToAct,
      );
      expect(firstToAct.value, equals((dealer.value + 1) % 4));
    });

    test('each view has exactly 3 opponents', () {
      for (final id in playerIds) {
        expect(session.viewFor(id).opponents, hasLength(3));
      }
    });

    test('opponents are in seats left, across, right', () {
      final view = session.viewFor(playerIds.first);
      final seats = view.opponents.map((o) => o.seat).toList();
      expect(seats, containsAll(RelativeSeat.values));
    });

    test('same seed reproduces the same deal', () {
      final session2 = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
      for (final id in playerIds) {
        expect(session.viewFor(id).hand, equals(session2.viewFor(id).hand));
      }
    });
  });

  group('View derivation', () {
    test('deriveViewDto hides opponents\' concealed cards', () {
      final state = MasterGameState(
        hands: <PlayerId, List<Card>>{
          PlayerId(0): [
            const Card(Suit.clubs, Rank.nine),
            const Card(Suit.spades, Rank.ace),
          ],
          PlayerId(1): [
            const Card(Suit.hearts, Rank.king),
            const Card(Suit.diamonds, Rank.ten),
          ],
          PlayerId(2): [
            const Card(Suit.clubs, Rank.queen),
            const Card(Suit.spades, Rank.nine),
          ],
          PlayerId(3): [
            const Card(Suit.hearts, Rank.jack),
            const Card(Suit.diamonds, Rank.seven),
          ],
        },
      );

      final view = deriveViewDto(state, PlayerId(0));

      expect(
        view.hand,
        containsAll([
          const Card(Suit.clubs, Rank.nine),
          const Card(Suit.spades, Rank.ace),
        ]),
      );
      expect(
        view.hand,
        isNot(
          containsAll([
            const Card(Suit.hearts, Rank.king),
            const Card(Suit.diamonds, Rank.ten),
          ]),
        ),
      );
    });
  });

  group('GameConfig validation', () {
    test(
      'mismatched deck and hand sizes throw ArgumentError at construction',
      () {
        final badConfig = GameConfig(
          playerCount: 4,
          handSize: 7, // 4*7+2 = 30 ≠ 26
          blindSize: 2,
          roundsPerGame: 4,
          deckComposition: DeckComposition.spitzer(),
        );
        expect(
          () => SheepheadGameSession(badConfig, RandomShuffler(Random(0))),
          throwsArgumentError,
        );
      },
    );
  });

  group('RandomShuffler', () {
    test('same seed produces the same order', () {
      final deck = DeckComposition.spitzer().cards;
      expect(
        RandomShuffler(Random(42)).shuffle(deck),
        equals(RandomShuffler(Random(42)).shuffle(deck)),
      );
    });

    test('different seeds produce different orders', () {
      final deck = DeckComposition.spitzer().cards;
      expect(
        RandomShuffler(Random(1)).shuffle(deck),
        isNot(equals(RandomShuffler(Random(2)).shuffle(deck))),
      );
    });
  });

  group('Pick phase — passing', () {
    late SheepheadGameSession session;

    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
    });

    // dealer=PlayerId(0), so first to act=PlayerId(1)

    test('PassCommandDto from wrong player is rejected', () {
      expect(session.submit(PassCommandDto(PlayerId(0))), isA<Rejected>());
    });

    test('PassCommandDto from correct player is accepted', () {
      expect(session.submit(PassCommandDto(PlayerId(1))), isA<Accepted>());
    });

    test('after pass, turn advances to next player', () {
      session.submit(PassCommandDto(PlayerId(1)));
      expect(session.viewFor(PlayerId(2)).isMyTurnToAct, isTrue);
    });

    test('passer shows isPassed in opponents views', () {
      session.submit(PassCommandDto(PlayerId(1)));
      final view = session.viewFor(PlayerId(0));
      final passer = view.opponents.firstWhere((o) => o.id == PlayerId(1));
      expect(passer.isPassed, isTrue);
    });

    test('all four passing transitions to AllPassPhaseViewDto', () {
      for (final id in [PlayerId(1), PlayerId(2), PlayerId(3), PlayerId(0)]) {
        session.submit(PassCommandDto(id));
      }
      expect(session.viewFor(PlayerId(0)).phase, isA<AllPassPhaseViewDto>());
    });
  });

  group('Pick phase — picking', () {
    late SheepheadGameSession session;
    final playerIds = List.generate(4, PlayerId.new);

    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
    });

    // dealer=PlayerId(0), so first to act=PlayerId(1)

    test('PickCommandDto from wrong player is rejected', () {
      expect(session.submit(PickCommandDto(PlayerId(0))), isA<Rejected>());
    });

    test('PickCommandDto from correct player is accepted', () {
      expect(session.submit(PickCommandDto(PlayerId(1))), isA<Accepted>());
    });

    test('after pick, all views show BuryPhaseViewDto', () {
      session.submit(PickCommandDto(PlayerId(1)));
      for (final id in playerIds) {
        expect(session.viewFor(id).phase, isA<BuryPhaseViewDto>());
      }
    });

    test('after pick, picker isIPicker is true', () {
      session.submit(PickCommandDto(PlayerId(1)));
      expect(session.viewFor(PlayerId(1)).isIPicker, isTrue);
    });

    test('after pick, picker has 8 cards', () {
      session.submit(PickCommandDto(PlayerId(1)));
      expect(session.viewFor(PlayerId(1)).hand, hasLength(8));
    });

    test('isChopAllowed reflects whether picker holds J♦', () {
      session.submit(PickCommandDto(PlayerId(1)));
      final fullHand = session.viewFor(PlayerId(1)).hand;
      final holdsJD = fullHand.contains(const Card(Suit.diamonds, Rank.jack));
      final buryView = session.viewFor(PlayerId(1)).phase as BuryPhaseViewDto;
      expect(buryView.isChopAllowed, equals(!holdsJD));
    });
  });

  group('Bury phase', () {
    // seed 0: picker (PlayerId(1)) gets 10♣ J♥ K♥ 10♥ A♣ 9♠ 10♦ A♠ — no J♦
    late SheepheadGameSession session;

    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
      session.submit(PickCommandDto(PlayerId(1)));
    });

    test('BuryCommandDto from non-picker is rejected', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      expect(
        session.submit(
          BuryCommandDto(
            playerId: PlayerId(0),
            cards: hand.take(2).toList(),
            chop: false,
          ),
        ),
        isA<Rejected>(),
      );
    });

    test('BuryCommandDto with wrong card count is rejected', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      expect(
        session.submit(
          BuryCommandDto(
            playerId: PlayerId(1),
            cards: [hand.first],
            chop: false,
          ),
        ),
        isA<Rejected>(),
      );
    });

    test('BuryCommandDto with a card not in hand is rejected', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      final notInHand = DeckComposition.spitzer().cards.firstWhere(
        (c) => !hand.contains(c),
      );
      expect(
        session.submit(
          BuryCommandDto(
            playerId: PlayerId(1),
            cards: [hand.first, notInHand],
            chop: false,
          ),
        ),
        isA<Rejected>(),
      );
    });

    test('valid BuryCommandDto is accepted', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      expect(
        session.submit(
          BuryCommandDto(
            playerId: PlayerId(1),
            cards: hand.take(2).toList(),
            chop: false,
          ),
        ),
        isA<Accepted>(),
      );
    });

    test('after bury, picker hand returns to 6 cards', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      session.submit(
        BuryCommandDto(
          playerId: PlayerId(1),
          cards: hand.take(2).toList(),
          chop: false,
        ),
      );
      expect(session.viewFor(PlayerId(1)).hand, hasLength(6));
    });

    test('after bury, all views show TrickPlayPhaseViewDto', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      session.submit(
        BuryCommandDto(
          playerId: PlayerId(1),
          cards: hand.take(2).toList(),
          chop: false,
        ),
      );
      for (final id in List.generate(4, PlayerId.new)) {
        expect(session.viewFor(id).phase, isA<TrickPlayPhaseViewDto>());
      }
    });
  });

  group('Bury phase — chop and J♦ rules', () {
    // seed 2: picker gets A♥ A♠ A♦ Q♦ J♠ J♦ 10♦ Q♣ — J♦ in hand
    late SheepheadGameSession session;
    late List<Card> pickerHand;
    final jD = const Card(Suit.diamonds, Rank.jack);

    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(2)),
      );
      session.submit(PickCommandDto(PlayerId(1)));
      pickerHand = session.viewFor(PlayerId(1)).hand;
    });

    test('chop while post-bury hand still holds J♦ is rejected', () {
      final bury = pickerHand.where((c) => c != jD).take(2).toList();
      expect(
        session.submit(
          BuryCommandDto(playerId: PlayerId(1), cards: bury, chop: true),
        ),
        isA<Rejected>(),
      );
    });

    test('burying J♦ without chop announcement is rejected', () {
      final bury = [jD, pickerHand.firstWhere((c) => c != jD)];
      expect(
        session.submit(
          BuryCommandDto(playerId: PlayerId(1), cards: bury, chop: false),
        ),
        isA<Rejected>(),
      );
    });

    test('burying J♦ with chop announcement is accepted', () {
      final bury = [jD, pickerHand.firstWhere((c) => c != jD)];
      expect(
        session.submit(
          BuryCommandDto(playerId: PlayerId(1), cards: bury, chop: true),
        ),
        isA<Accepted>(),
      );
    });
  });

  group('Trick play phase', () {
    late SheepheadGameSession session;
    final playerIds = List.generate(4, PlayerId.new);

    // seed 0: dealer=0, PlayerId(1) picks; after burying first 2 cards, leader=1
    setUp(() {
      session = SheepheadGameSession(
        GameConfig.spitzer4(),
        RandomShuffler(Random(0)),
      );
      session.submit(PickCommandDto(PlayerId(1)));
      final hand = session.viewFor(PlayerId(1)).hand;
      session.submit(
        BuryCommandDto(
          playerId: PlayerId(1),
          cards: hand.take(2).toList(),
          chop: false,
        ),
      );
    });

    // Play any valid card for the current active player.
    // Tries each card in hand order; rejected cards leave state unchanged.
    void playAny(PlayerId id) {
      for (final card in session.viewFor(id).hand) {
        if (session.submit(PlayCardCommandDto(playerId: id, card: card))
            is Accepted) {
          return;
        }
      }
      fail('no valid card found for player ${id.value}');
    }

    test('first to act after bury is left of dealer (PlayerId(1))', () {
      expect(session.viewFor(PlayerId(1)).isMyTurnToAct, isTrue);
      for (final id in [PlayerId(0), PlayerId(2), PlayerId(3)]) {
        expect(session.viewFor(id).isMyTurnToAct, isFalse);
      }
    });

    test('PlayCardCommandDto from wrong player is rejected', () {
      final card = session.viewFor(PlayerId(0)).hand.first;
      expect(
        session.submit(PlayCardCommandDto(playerId: PlayerId(0), card: card)),
        isA<Rejected>(),
      );
    });

    test('PlayCardCommandDto with card not in hand is rejected', () {
      final hand = session.viewFor(PlayerId(1)).hand;
      final notInHand = DeckComposition.spitzer().cards.firstWhere(
        (c) => !hand.contains(c),
      );
      expect(
        session.submit(
          PlayCardCommandDto(playerId: PlayerId(1), card: notInHand),
        ),
        isA<Rejected>(),
      );
    });

    test('valid PlayCardCommandDto is accepted', () {
      final card = session.viewFor(PlayerId(1)).hand.first;
      expect(
        session.submit(PlayCardCommandDto(playerId: PlayerId(1), card: card)),
        isA<Accepted>(),
      );
    });

    test('played card appears in opponent view as cardPlayed', () {
      final card = session.viewFor(PlayerId(1)).hand.first;
      session.submit(PlayCardCommandDto(playerId: PlayerId(1), card: card));
      final opp = session
          .viewFor(PlayerId(0))
          .opponents
          .firstWhere((o) => o.id == PlayerId(1));
      expect(opp.cardPlayed, equals(card));
    });

    test('turn advances to next player after one card played', () {
      playAny(PlayerId(1));
      expect(session.viewFor(PlayerId(2)).isMyTurnToAct, isTrue);
    });

    test('after 4 cards played trick clears and exactly one player leads', () {
      playAny(PlayerId(1));
      playAny(PlayerId(2));
      playAny(PlayerId(3));
      playAny(PlayerId(0));

      final acting = playerIds
          .where((id) => session.viewFor(id).isMyTurnToAct)
          .toList();
      expect(acting, hasLength(1));

      // No mid-trick card should be visible after trick completes
      final view = session.viewFor(acting.first);
      for (final opp in view.opponents) {
        expect(opp.cardPlayed, isNull);
      }
    });

    test('after 6 tricks all views show HandResultPhaseViewDto', () {
      for (var trick = 0; trick < 6; trick++) {
        for (var i = 0; i < 4; i++) {
          final acting = playerIds.firstWhere(
            (id) => session.viewFor(id).isMyTurnToAct,
          );
          playAny(acting);
        }
      }
      for (final id in playerIds) {
        expect(session.viewFor(id).phase, isA<HandResultPhaseViewDto>());
      }
    });

    test('HandResultPhaseViewDto contains 4 player scores', () {
      for (var trick = 0; trick < 6; trick++) {
        for (var i = 0; i < 4; i++) {
          final acting = playerIds.firstWhere(
            (id) => session.viewFor(id).isMyTurnToAct,
          );
          playAny(acting);
        }
      }
      final result =
          session.viewFor(PlayerId(0)).phase as HandResultPhaseViewDto;
      expect(result.results, hasLength(4));
    });

    test('hand points sum to zero (alone) or ±1 (partner game)', () {
      // Partner game: picker±2, partner±1, two defenders∓1 → total ±1.
      // Alone game: picker±3, three defenders∓1 → total 0.
      for (var trick = 0; trick < 6; trick++) {
        for (var i = 0; i < 4; i++) {
          final acting = playerIds.firstWhere(
            (id) => session.viewFor(id).isMyTurnToAct,
          );
          playAny(acting);
        }
      }
      final result =
          session.viewFor(PlayerId(0)).phase as HandResultPhaseViewDto;
      final total = result.results.fold<int>(0, (s, r) => s + r.handPoints);
      expect(total.abs(), lessThanOrEqualTo(1));
    });

    test('must follow trump when trump is led', () {
      final hand1 = session.viewFor(PlayerId(1)).hand;
      final trumpCard = hand1.firstWhere(TrumpEvaluator.isTrump);
      session.submit(
        PlayCardCommandDto(playerId: PlayerId(1), card: trumpCard),
      );

      final hand2 = session.viewFor(PlayerId(2)).hand;
      final hasTrump = hand2.any(TrumpEvaluator.isTrump);
      final nonTrump = hand2.where((c) => !TrumpEvaluator.isTrump(c)).toList();

      if (hasTrump && nonTrump.isNotEmpty) {
        expect(
          session.submit(
            PlayCardCommandDto(playerId: PlayerId(2), card: nonTrump.first),
          ),
          isA<Rejected>(),
        );
      }
    });
  });

  group('DeckComposition.spitzer', () {
    late List<Card> deck;

    setUp(() => deck = DeckComposition.spitzer().cards);

    test('has exactly 26 cards', () => expect(deck, hasLength(26)));

    test('contains 7♦ and 8♦', () {
      expect(deck, contains(const Card(Suit.diamonds, Rank.seven)));
      expect(deck, contains(const Card(Suit.diamonds, Rank.eight)));
    });

    test('does not contain 7 or 8 of non-diamond suits', () {
      for (final suit in [Suit.clubs, Suit.spades, Suit.hearts]) {
        expect(deck, isNot(contains(Card(suit, Rank.seven))));
        expect(deck, isNot(contains(Card(suit, Rank.eight))));
      }
    });

    test(
      'has no duplicate cards',
      () => expect(deck.toSet(), hasLength(deck.length)),
    );
  });
}
