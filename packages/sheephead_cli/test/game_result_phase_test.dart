import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late GameResultPhase phase;

  setUp(() {
    phase = GameResultPhase();
  });

  PlayerView makeView({
    List<PlayerScore> standings = const [],
    bool endedOnPassedOutHand = false,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: const [],
    opponents: const [],
    isMyTurnToAct: false,
    phase: GameResultPhaseView(
      standings: standings,
      endedOnPassedOutHand: endedOnPassedOutHand,
    ),
  );

  const standings = [
    PlayerScore(id: PlayerId(2), handPoints: 3, runningTotal: 21),
    PlayerScore(id: PlayerId(0), handPoints: -1, runningTotal: 8),
    PlayerScore(id: PlayerId(1), handPoints: -1, runningTotal: -12),
    PlayerScore(id: PlayerId(3), handPoints: -1, runningTotal: -17),
  ];

  group('buildContent', () {
    test('announces the game is over', () {
      expect(phase.buildContent(makeView()), contains('Game Over'));
    });

    test('shows the exit prompt', () {
      expect(phase.buildContent(makeView()), contains('Press Enter to exit'));
    });

    test('tells the player to re-run for another game', () {
      expect(phase.buildContent(makeView()), contains('Run the program again'));
    });

    test('shows each player final running total', () {
      final content = phase.buildContent(makeView(standings: standings));

      expect(content, contains('+21'));
      expect(content, contains('+8'));
      expect(content, contains('-12'));
      expect(content, contains('-17'));
    });

    test('shows a zero total with a plus sign', () {
      final content = phase.buildContent(
        makeView(
          standings: [
            const PlayerScore(id: PlayerId(0), handPoints: 0, runningTotal: 0),
          ],
        ),
      );

      expect(content, contains('+0'));
    });

    test('labels the viewing player as "You"', () {
      final content = phase.buildContent(makeView(standings: standings));

      expect(content, contains('You'));
    });

    test('labels other players by number', () {
      final content = phase.buildContent(makeView(standings: standings));

      expect(content, contains('Player 2'));
    });

    test('marks the player with the highest total as the winner', () {
      final content = phase.buildContent(makeView(standings: standings));
      final winnerLine = content
          .split('\n')
          .firstWhere((l) => l.contains('winner'));

      expect(winnerLine, contains('+21'));
    });

    test('does not mark a non-leading player as the winner', () {
      final content = phase.buildContent(makeView(standings: standings));
      final winnerLines = content
          .split('\n')
          .where((l) => l.contains('winner'))
          .toList();

      expect(winnerLines, hasLength(1));
    });

    test('notes when the game ended on a passed-out final hand', () {
      final content = phase.buildContent(
        makeView(standings: standings, endedOnPassedOutHand: true),
      );

      expect(content, contains('passed out'));
    });

    test('omits the passed-out note on a normal ending', () {
      final content = phase.buildContent(makeView(standings: standings));

      expect(content, isNot(contains('passed out')));
    });
  });

  group('interpret', () {
    test('empty input quits', () {
      expect(phase.interpret(''), isA<Quit>());
    });

    test('whitespace-only input quits', () {
      expect(phase.interpret('  '), isA<Quit>());
    });

    test('any other input is Unrecognized', () {
      expect(phase.interpret('x'), isA<Unrecognized>());
    });
  });
}
