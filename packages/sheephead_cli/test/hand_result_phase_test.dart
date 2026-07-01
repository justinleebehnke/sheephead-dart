import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late HandResultPhase phase;

  setUp(() {
    phase = HandResultPhase();
  });

  PlayerView makeView({
    List<PlayerScore>? results,
    bool isIPicker = false,
    bool isIDealer = false,
    bool isIGoingAlone = false,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: const [],
    opponents: const [
      SeatedPlayer(
        id: PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: false,
        isDealer: false,
        isPicker: true,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: false,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: false,
    isIPicker: isIPicker,
    isIDealer: isIDealer,
    isIGoingAlone: isIGoingAlone,
    handResults: results,
  );

  group('buildContent', () {
    test('shows Hand Result title', () {
      expect(phase.buildContent(makeView()), contains('Hand Result'));
    });

    test('shows press Enter prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Press Enter to continue'),
      );
    });

    test('shows positive hand points with a plus sign', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 3),
          ],
        ),
      );
      expect(content, contains('+3 pts'));
    });

    test('shows negative hand points', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(
              id: PlayerId(2),
              handPoints: -1,
              runningTotal: -1,
            ),
          ],
        ),
      );
      expect(content, contains('-1 pts'));
    });

    test('shows running total distinct from hand points', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 8),
          ],
        ),
      );
      expect(content, contains('(total: +8)'));
    });

    test('shows negative running total', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(
              id: PlayerId(2),
              handPoints: -1,
              runningTotal: -4,
            ),
          ],
        ),
      );
      expect(content, contains('(total: -4)'));
    });

    test('shows picker label for picker opponent', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(
              id: PlayerId(2),
              handPoints: -1,
              runningTotal: -1,
            ),
          ],
        ),
      );
      expect(content, contains('Player 2 picked'));
    });

    test('shows dealer marker for dealer opponent', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(
              id: PlayerId(3),
              handPoints: -1,
              runningTotal: -1,
            ),
          ],
        ),
      );
      expect(content, contains('Player 3 (D)'));
    });

    test('shows picker label when I am the picker', () {
      final content = phase.buildContent(
        makeView(
          isIPicker: true,
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 3),
          ],
        ),
      );
      expect(content, contains('Player 0 picked'));
    });

    test('does not show picker label when I am not the picker', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 3),
          ],
        ),
      );
      expect(content, isNot(contains('Player 0 picked')));
    });

    test('shows chop label when I am the picker going alone', () {
      final content = phase.buildContent(
        makeView(
          isIPicker: true,
          isIGoingAlone: true,
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 9, runningTotal: 9),
          ],
        ),
      );
      expect(content, contains('Player 0 picked (chop)'));
    });

    test('shows dealer marker when I am the dealer', () {
      final content = phase.buildContent(
        makeView(
          isIDealer: true,
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 3),
          ],
        ),
      );
      expect(content, contains('Player 0 (D)'));
    });

    test('shows zero hand points with a plus sign', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(id: PlayerId(0), handPoints: 0, runningTotal: 0),
          ],
        ),
      );
      expect(content, contains('+0 pts'));
    });

    test('shows all players when multiple results are provided', () {
      final content = phase.buildContent(
        makeView(
          results: [
            const PlayerScore(
              id: PlayerId(2),
              handPoints: -1,
              runningTotal: -1,
            ),
            const PlayerScore(id: PlayerId(0), handPoints: 3, runningTotal: 3),
          ],
        ),
      );
      expect(content, contains('+3 pts'));
      expect(content, contains('-1 pts'));
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
