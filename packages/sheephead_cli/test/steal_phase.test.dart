import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late StealPhase phase;

  setUp(() {
    phase = StealPhase();
  });

  PlayerViewDto makeView({List<Card> hand = const []}) => PlayerViewDto(
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
        isPassed: false,
        isDealer: false,
        isPicker: true,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: false,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: true,
    phase: const StealPhaseViewDto(),
  );

  group('buildContent', () {
    test('shows steal prompt', () {
      expect(
        phase.buildContent(makeView()),
        contains('Would you like to steal? [y/N]'),
      );
    });

    test('shows hand when non-empty', () {
      final content = phase.buildContent(
        makeView(
          hand: [
            const Card(Suit.clubs, Rank.queen),
            const Card(Suit.hearts, Rank.ace),
          ],
        ),
      );

      expect(content, contains('Q♣, A♥'));
    });

    test('shows opponents in table layout', () {
      final content = phase.buildContent(makeView());

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
    });

    test('labels the picker', () {
      expect(phase.buildContent(makeView()), contains('Player 2 picked'));
    });
  });

  group('buildContent opponent labels', () {
    PlayerViewDto viewWithAcross(SeatedPlayer across) => PlayerViewDto(
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
        ),
        across,
        SeatedPlayer(
          id: const PlayerId(3),
          seat: RelativeSeat.right,
          isPassed: false,
          isDealer: true,
          isPicker: false,
          isGoingAlone: false,
        ),
      ],
      isMyTurnToAct: true,
      phase: const StealPhaseViewDto(),
    );

    test('labels a player who declined the steal', () {
      final content = phase.buildContent(
        viewWithAcross(
          const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: false,
            isGoingAlone: false,
            isDeclinedSteal: true,
          ),
        ),
      );

      expect(content, contains('Player 2 declined steal'));
    });

    test('labels the stealer', () {
      final content = phase.buildContent(
        viewWithAcross(
          const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: false,
            isGoingAlone: true,
            isStealer: true,
          ),
        ),
      );

      expect(content, contains('Player 2 stole the blind'));
    });

    test('labels the robbed picker as ally', () {
      final content = phase.buildContent(
        viewWithAcross(
          const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: true,
            isGoingAlone: false,
            isRobbed: true,
          ),
        ),
      );

      expect(content, contains('Player 2 picked (ally)'));
    });

    test('labels the picker going alone as chop', () {
      final content = phase.buildContent(
        viewWithAcross(
          const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: true,
            isGoingAlone: true,
          ),
        ),
      );

      expect(content, contains('Player 2 picked (chop)'));
    });
  });

  group('interpret', () {
    test('"y" submits StealCommandDto', () {
      expect(phase.interpret('y'), isA<Submit>());
      expect((phase.interpret('y') as Submit).command, isA<StealCommandDto>());
    });

    test('"Y" submits StealCommandDto', () {
      expect((phase.interpret('Y') as Submit).command, isA<StealCommandDto>());
    });

    test('"n" submits DeclineStealCommandDto', () {
      expect(phase.interpret('n'), isA<Submit>());
      expect(
        (phase.interpret('n') as Submit).command,
        isA<DeclineStealCommandDto>(),
      );
    });

    test('"N" submits DeclineStealCommandDto', () {
      expect(
        (phase.interpret('N') as Submit).command,
        isA<DeclineStealCommandDto>(),
      );
    });

    test('empty input submits DeclineStealCommandDto (default no)', () {
      expect(
        (phase.interpret('') as Submit).command,
        isA<DeclineStealCommandDto>(),
      );
    });

    test('unrecognized input returns Unrecognized', () {
      expect(phase.interpret('steal'), isA<Unrecognized>());
    });
  });
}
