import 'dart:math';

import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

class _FakeSession implements GameSession {
  _FakeSession({
    required PlayerView view,
    CommandResult Function(Command)? onSubmit,
  }) : _view = view,
       _onSubmit = onSubmit ?? _accept;

  static CommandResult _accept(Command c) => const Accepted();

  final PlayerView _view;
  final CommandResult Function(Command) _onSubmit;
  final List<Command> commands = [];

  @override
  PlayerView viewFor(PlayerId id) => _view;

  @override
  CommandResult submit(Command command) {
    commands.add(command);
    return _onSubmit(command);
  }

  @override
  void addObserver(GameObserver observer) {}

  @override
  void removeObserver(GameObserver observer) {}
}

const _id = PlayerId(1);
const _hand = [
  Card(Suit.clubs, Rank.ace),
  Card(Suit.clubs, Rank.king),
  Card(Suit.spades, Rank.nine),
];

PlayerView _view({
  required bool isMyTurn,
  required PhaseView phase,
  List<Card> hand = _hand,
}) => PlayerView(
  id: _id,
  hand: hand,
  opponents: const <SeatedPlayer>[],
  isMyTurnToAct: isMyTurn,
  phase: phase,
);

void main() {
  group('RandomAi — pick phase', () {
    test('submits PassCommand when it is their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const PickPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, hasLength(1));
      final cmd = session.commands.single as PassCommand;
      expect(cmd.playerId, equals(_id));
    });

    test('submits nothing when it is not their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: false, phase: const PickPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, isEmpty);
    });
  });

  group('RandomAi — trick play phase', () {
    test('submits PlayCardCommand with a card from hand when their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const TrickPlayPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, hasLength(1));
      final cmd = session.commands.single as PlayCardCommand;
      expect(_hand, contains(cmd.card));
    });

    test('submits nothing when it is not their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: false, phase: const TrickPlayPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, isEmpty);
    });

    test('retries until a card is accepted', () {
      const rejected = Card(Suit.clubs, Rank.ace);
      const accepted = Card(Suit.clubs, Rank.king);
      final session = _FakeSession(
        view: _view(
          isMyTurn: true,
          phase: const TrickPlayPhaseView(),
          hand: [rejected, accepted],
        ),
        onSubmit: (cmd) => cmd is PlayCardCommand && cmd.card == rejected
            ? const Rejected('must follow suit')
            : const Accepted(),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      final plays = session.commands.whereType<PlayCardCommand>().toList();
      expect(plays.last.card, equals(accepted));
    });

    test('submits exactly one command when first card is accepted', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const TrickPlayPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, hasLength(1));
    });
  });

  group('RandomAi — other phases', () {
    test('submits nothing during AllPassPhaseView', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const AllPassPhaseView()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, isEmpty);
    });
  });
}
