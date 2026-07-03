import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late BurySelection selection;

  setUp(() => selection = BurySelection());

  PlayerView viewFor(PhaseView phase) => PlayerView(
    id: const PlayerId(0),
    hand: const [],
    opponents: const [],
    isMyTurnToAct: true,
    phase: phase,
  );

  test('PickPhaseView selects PickPassPhase', () {
    expect(
      selectPhase(viewFor(const PickPhaseView()), selection),
      isA<PickPassPhase>(),
    );
  });

  test('AllPassPhaseView selects AllPassPhase', () {
    expect(
      selectPhase(viewFor(const AllPassPhaseView()), selection),
      isA<AllPassPhase>(),
    );
  });

  test('BuryPhaseView with no stored selection selects BuryPhase', () {
    expect(
      selectPhase(viewFor(const BuryPhaseView(isChopAllowed: true)), selection),
      isA<BuryPhase>(),
    );
  });

  test('BuryPhaseView with a stored selection selects ChopPhase', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    expect(
      selectPhase(viewFor(const BuryPhaseView(isChopAllowed: true)), selection),
      isA<ChopPhase>(),
    );
  });

  test('StealPhaseView selects StealPhase', () {
    expect(
      selectPhase(viewFor(const StealPhaseView()), selection),
      isA<StealPhase>(),
    );
  });

  test('TrickPlayPhaseView selects TrickPlayPhase', () {
    expect(
      selectPhase(viewFor(const TrickPlayPhaseView()), selection),
      isA<TrickPlayPhase>(),
    );
  });

  test('TrickResultPhaseView selects TrickResultPhase', () {
    expect(
      selectPhase(
        viewFor(
          const TrickResultPhaseView(
            cardPlayed: Card(Suit.clubs, Rank.queen),
            trickWinnerId: PlayerId(2),
          ),
        ),
        selection,
      ),
      isA<TrickResultPhase>(),
    );
  });

  test('HandResultPhaseView selects HandResultPhase', () {
    expect(
      selectPhase(viewFor(const HandResultPhaseView(results: [])), selection),
      isA<HandResultPhase>(),
    );
  });

  test('GameResultPhaseView selects GameResultPhase', () {
    expect(
      selectPhase(viewFor(const GameResultPhaseView(standings: [])), selection),
      isA<GameResultPhase>(),
    );
  });

  test('entering GameResultPhase clears a stale bury selection', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    selectPhase(viewFor(const GameResultPhaseView(standings: [])), selection);
    expect(selection.cards, isNull);
  });

  test('entering HandResultPhase clears a stale bury selection', () {
    selection.cards = [
      const Card(Suit.clubs, Rank.queen),
      const Card(Suit.spades, Rank.ace),
    ];
    selectPhase(viewFor(const HandResultPhaseView(results: [])), selection);
    expect(selection.cards, isNull);
  });
}
