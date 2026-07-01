import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  const storedCards = [
    Card(Suit.clubs, Rank.queen),
    Card(Suit.spades, Rank.nine),
  ];

  late BurySelection selection;
  late ChopPhase phase;

  setUp(() {
    selection = BurySelection()..cards = storedCards;
    phase = ChopPhase(selection);
  });

  PlayerView makeView({List<Card> hand = const []}) => PlayerView(
    id: const PlayerId(0),
    hand: hand,
    opponents: [
      SeatedPlayer(
        id: const PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: true,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: true,
    isIPicker: true,
    isChopAllowed: true,
  );

  group('buildContent', () {
    test('shows chop prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Would you like to chop (go alone)? [y/N]'),
      );
    });

    test('shows hand', () {
      final content = phase.buildContent(
        makeView(
          hand: [
            const Card(Suit.clubs, Rank.queen),
            const Card(Suit.diamonds, Rank.jack),
          ],
        ),
      );

      expect(content, contains('Q♣, J♦'));
    });

    test('shows opponents in table layout', () {
      final content = phase.buildContent(makeView());

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
    });
  });

  group('interpret', () {
    test('"y" submits BuryCommand with chop true and the stored cards', () {
      final result = phase.interpret('y');

      expect(result, isA<Submit>());
      final cmd = (result as Submit).command as BuryCommand;
      expect(cmd.chop, isTrue);
      expect(cmd.cards, storedCards);
    });

    test('"Y" submits BuryCommand with chop true', () {
      final result = phase.interpret('Y');

      expect(result, isA<Submit>());
      expect(((result as Submit).command as BuryCommand).chop, isTrue);
    });

    test('"n" submits BuryCommand with chop false', () {
      final result = phase.interpret('n');

      expect(result, isA<Submit>());
      expect(((result as Submit).command as BuryCommand).chop, isFalse);
    });

    test('"N" submits BuryCommand with chop false', () {
      final result = phase.interpret('N');

      expect(result, isA<Submit>());
      expect(((result as Submit).command as BuryCommand).chop, isFalse);
    });

    test('empty input submits BuryCommand with chop false (default no)', () {
      final result = phase.interpret('');

      expect(result, isA<Submit>());
      expect(((result as Submit).command as BuryCommand).chop, isFalse);
    });

    test('unrecognized input returns Unrecognized', () {
      expect(phase.interpret('maybe'), isA<Unrecognized>());
    });
  });
}
