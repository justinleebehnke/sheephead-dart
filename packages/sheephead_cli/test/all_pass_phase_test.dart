import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late AllPassPhase phase;

  setUp(() {
    phase = AllPassPhase();
  });

  PlayerView makeView() => PlayerView(
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
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: true,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: false,
    phase: const AllPassPhaseView(),
  );

  group('buildContent', () {
    test('announces that everyone passed', () {
      expect(phase.buildContent(makeView()), contains('Everyone passed'));
    });

    test('shows press Enter prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Press Enter to continue'),
      );
    });

    test('announces the redealt hand is a doubles hand', () {
      expect(phase.buildContent(makeView()), contains('doubles hand'));
    });

    test('shows opponents in table layout', () {
      final content = phase.buildContent(makeView());

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
    });

    test('shows the dealer who redeals', () {
      expect(phase.buildContent(makeView()), contains('Player 3 (D)'));
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
