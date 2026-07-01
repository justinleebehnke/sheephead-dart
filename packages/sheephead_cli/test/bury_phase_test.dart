import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late BurySelection selection;
  late BuryPhase phase;

  const hand8 = [
    Card(Suit.clubs, Rank.queen),
    Card(Suit.diamonds, Rank.seven),
    Card(Suit.diamonds, Rank.jack),
    Card(Suit.hearts, Rank.ace),
    Card(Suit.clubs, Rank.ten),
    Card(Suit.spades, Rank.nine),
    Card(Suit.diamonds, Rank.ace),
    Card(Suit.clubs, Rank.king),
  ];

  setUp(() {
    selection = BurySelection();
    phase = BuryPhase(selection);
  });

  PlayerView makeView({
    List<Card> hand = const [],
    bool isChopAllowed = false,
    bool leftPassed = false,
    bool rightDealer = false,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: hand,
    opponents: [
      SeatedPlayer(
        id: const PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: leftPassed,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: false,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: false,
        isDealer: rightDealer,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: true,
    isIPicker: true,
    isChopAllowed: isChopAllowed,
  );

  group('buildContent', () {
    test('shows each hand card with a number', () {
      final content = phase.buildContent(makeView(hand: hand8));

      expect(content, contains('1:Q♣'));
      expect(content, contains('3:J♦'));
      expect(content, contains('8:K♣'));
    });

    test('shows all 8 cards on one line', () {
      final lines = phase.buildContent(makeView(hand: hand8)).split('\n');

      expect(
        lines.any((String l) => l.contains('1:Q♣') && l.contains('8:K♣')),
        isTrue,
      );
    });

    test('shows bury prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Bury 2 cards (e.g. 1,3):'),
      );
    });

    test('does not mention chop', () {
      expect(phase.buildContent(makeView()), isNot(contains('chop')));
    });

    test('shows opponents in table layout', () {
      final content = phase.buildContent(
        makeView(leftPassed: true, rightDealer: true),
      );

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
      expect(content, contains('Player 1 passed'));
      expect(content, contains('Player 3 (D)'));
    });
  });

  group('interpret when chop is allowed', () {
    setUp(() => phase.buildContent(makeView(hand: hand8, isChopAllowed: true)));

    test('"1,3" stores the selected cards and advances', () {
      final result = phase.interpret('1,3');

      expect(result, isA<Advance>());
      expect(selection.cards, containsAll([hand8[0], hand8[2]]));
    });

    test('"2,5" stores the selected cards and advances', () {
      final result = phase.interpret('2,5');

      expect(result, isA<Advance>());
      expect(selection.cards, containsAll([hand8[1], hand8[4]]));
    });
  });

  group('interpret when chop is not allowed', () {
    setUp(
      () => phase.buildContent(makeView(hand: hand8, isChopAllowed: false)),
    );

    test('"1,3" submits BuryCommand directly with chop false', () {
      final result = phase.interpret('1,3');

      expect(result, isA<Submit>());
      final cmd = (result as Submit).command as BuryCommand;
      expect(cmd.cards, containsAll([hand8[0], hand8[2]]));
      expect(cmd.chop, isFalse);
    });
  });

  group('interpret validation', () {
    setUp(
      () => phase.buildContent(makeView(hand: hand8, isChopAllowed: false)),
    );

    test('duplicate index is Unrecognized', () {
      expect(phase.interpret('3,3'), isA<Unrecognized>());
    });

    test('index 0 is out of range and Unrecognized', () {
      expect(phase.interpret('0,3'), isA<Unrecognized>());
    });

    test('index beyond hand size is Unrecognized', () {
      expect(phase.interpret('1,9'), isA<Unrecognized>());
    });

    test('only one index is Unrecognized', () {
      expect(phase.interpret('3'), isA<Unrecognized>());
    });

    test('garbage input is Unrecognized', () {
      expect(phase.interpret('bury these'), isA<Unrecognized>());
    });
  });
}
