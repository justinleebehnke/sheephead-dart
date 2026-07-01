import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late TrickResultPhase phase;

  setUp(() {
    phase = TrickResultPhase();
  });

  PlayerView makeView({
    PlayerId? winnerId,
    Card? myCard,
    Card? leftPlayed,
    Card? acrossPlayed,
    Card? rightPlayed,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: const [],
    opponents: [
      SeatedPlayer(
        id: const PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: leftPlayed,
      ),
      SeatedPlayer(
        id: const PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: false,
        isDealer: false,
        isPicker: true,
        isGoingAlone: false,
        cardPlayed: acrossPlayed,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: false,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: rightPlayed,
      ),
    ],
    isMyTurnToAct: false,
    cardPlayed: myCard,
    trickWinnerId: winnerId,
  );

  group('buildContent', () {
    test('shows press Enter prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Press Enter to continue'),
      );
    });

    test('shows opponent wins the trick', () {
      final content = phase.buildContent(makeView(winnerId: const PlayerId(2)));
      expect(content, contains('Player 2 wins the trick'));
    });

    test('shows "You win the trick" when the current player won', () {
      final content = phase.buildContent(makeView(winnerId: const PlayerId(0)));
      expect(content, contains('You win the trick'));
    });

    test('shows my played card', () {
      final content = phase.buildContent(
        makeView(myCard: const Card(Suit.clubs, Rank.queen)),
      );
      expect(content, contains('Q♣'));
    });

    test('shows across opponent card', () {
      final content = phase.buildContent(
        makeView(acrossPlayed: const Card(Suit.diamonds, Rank.ten)),
      );
      expect(content, contains('10♦'));
    });

    test('winner announcement appears below the table', () {
      final content = phase.buildContent(
        makeView(
          acrossPlayed: const Card(Suit.clubs, Rank.ace),
          winnerId: const PlayerId(2),
        ),
      );
      expect(
        content.indexOf('Player 2 picked'),
        lessThan(content.indexOf('Player 2 wins the trick')),
      );
    });

    test('does not show passed status', () {
      expect(phase.buildContent(makeView()), isNot(contains('passed')));
    });

    test('does not show declined steal status', () {
      final content = phase.buildContent(
        makeView(leftPlayed: const Card(Suit.spades, Rank.king)),
      );
      expect(content, isNot(contains('declined steal')));
    });
  });

  group('interpret', () {
    test('empty input advances', () {
      expect(phase.interpret(''), isA<Advance>());
    });

    test('whitespace-only input advances', () {
      expect(phase.interpret('  '), isA<Advance>());
    });

    test('any other input is Unrecognized', () {
      expect(phase.interpret('x'), isA<Unrecognized>());
    });
  });
}
