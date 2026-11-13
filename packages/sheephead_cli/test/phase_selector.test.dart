import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late BurySelection selection;

  setUp(() => selection = BurySelection());

  PlayerViewDto viewFor(PhaseViewDto phase) => PlayerViewDto(
    id: const PlayerId(0),
    hand: const [],
    opponents: const [],
    isMyTurnToAct: true,
    phase: phase,
  );

  test('PickPhaseViewDto selects PickPassPhase', () {
    expect(
      selectPhase(viewFor(const PickPhaseViewDto()), selection),
      isA<PickPassPhase>(),
    );
  });

  test('AllPassPhaseViewDto selects AllPassPhase', () {
    expect(
      selectPhase(viewFor(const AllPassPhaseViewDto()), selection),
      isA<AllPassPhase>(),
    );
  });

  test('BuryPhaseViewDto with no stored selection selects BuryPhase', () {
    expect(
      selectPhase(
        viewFor(const BuryPhaseViewDto(isChopAllowed: true)),
        selection,
      ),
      isA<BuryPhase>(),
    );
  });

  test('BuryPhaseViewDto with a stored selection selects ChopPhase', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    expect(
      selectPhase(
        viewFor(const BuryPhaseViewDto(isChopAllowed: true)),
        selection,
      ),
      isA<ChopPhase>(),
    );
  });

  test('StealPhaseViewDto selects StealPhase', () {
    expect(
      selectPhase(viewFor(const StealPhaseViewDto()), selection),
      isA<StealPhase>(),
    );
  });

  test('TrickPlayPhaseViewDto selects TrickPlayPhase', () {
    expect(
      selectPhase(viewFor(const TrickPlayPhaseViewDto()), selection),
      isA<TrickPlayPhase>(),
    );
  });

  test('TrickResultPhaseViewDto selects TrickResultPhase', () {
    expect(
      selectPhase(
        viewFor(
          const TrickResultPhaseViewDto(
            cardPlayed: Card(Suit.clubs, Rank.queen),
            trickWinnerId: PlayerId(2),
          ),
        ),
        selection,
      ),
      isA<TrickResultPhase>(),
    );
  });

  test('HandResultPhaseViewDto selects HandResultPhase', () {
    expect(
      selectPhase(
        viewFor(const HandResultPhaseViewDto(results: [])),
        selection,
      ),
      isA<HandResultPhase>(),
    );
  });

  test('GameResultPhaseViewDto selects GameResultPhase', () {
    expect(
      selectPhase(
        viewFor(const GameResultPhaseViewDto(standings: [])),
        selection,
      ),
      isA<GameResultPhase>(),
    );
  });

  test('entering GameResultPhase clears a stale bury selection', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    selectPhase(
      viewFor(const GameResultPhaseViewDto(standings: [])),
      selection,
    );
    expect(selection.cards, isNull);
  });

  test('entering HandResultPhase clears a stale bury selection', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    selectPhase(viewFor(const HandResultPhaseViewDto(results: [])), selection);
    expect(selection.cards, isNull);
  });
}
