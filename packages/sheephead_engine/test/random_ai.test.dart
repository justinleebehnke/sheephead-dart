import 'dart:math';

import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

class _FakeSession implements IGameSession {
  _FakeSession({
    required PlayerViewDto view,
    CommandResultDto Function(CommandDto)? onSubmit,
  }) : _view = view,
       _onSubmit = onSubmit ?? _accept;

  static CommandResultDto _accept(CommandDto c) => const Accepted();

  final PlayerViewDto _view;
  final CommandResultDto Function(CommandDto) _onSubmit;
  final List<CommandDto> commands = [];

  @override
  PlayerViewDto viewFor(PlayerId id) => _view;

  @override
  CommandResultDto submit(CommandDto command) {
    commands.add(command);
    return _onSubmit(command);
  }

  @override
  void addObserver(IGameObserver observer) {}

  @override
  void removeObserver(IGameObserver observer) {}
}

const _id = PlayerId(1);
const _hand = [
  Card(Suit.clubs, Rank.ace),
  Card(Suit.clubs, Rank.king),
  Card(Suit.spades, Rank.nine),
];

PlayerViewDto _view({
  required bool isMyTurn,
  required PhaseViewDto phase,
  List<Card> hand = _hand,
}) => PlayerViewDto(
  id: _id,
  hand: hand,
  opponents: const <SeatedPlayer>[],
  isMyTurnToAct: isMyTurn,
  phase: phase,
);

void main() {
  group('RandomAi — pick phase', () {
    test('submits PassCommandDto when it is their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const PickPhaseViewDto()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, hasLength(1));
      final cmd = session.commands.single as PassCommandDto;
      expect(cmd.playerId, equals(_id));
    });

    test('submits nothing when it is not their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: false, phase: const PickPhaseViewDto()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, isEmpty);
    });
  });

  group('RandomAi — trick play phase', () {
    test(
      'submits PlayCardCommandDto with a card from hand when their turn',
      () {
        final session = _FakeSession(
          view: _view(isMyTurn: true, phase: const TrickPlayPhaseViewDto()),
        );
        RandomAi(_id, session, Random(0)).onChanged();
        expect(session.commands, hasLength(1));
        final cmd = session.commands.single as PlayCardCommandDto;
        expect(_hand, contains(cmd.card));
      },
    );

    test('submits nothing when it is not their turn', () {
      final session = _FakeSession(
        view: _view(isMyTurn: false, phase: const TrickPlayPhaseViewDto()),
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
          phase: const TrickPlayPhaseViewDto(),
          hand: [rejected, accepted],
        ),
        onSubmit: (cmd) => cmd is PlayCardCommandDto && cmd.card == rejected
            ? const Rejected('must follow suit')
            : const Accepted(),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      final plays = session.commands.whereType<PlayCardCommandDto>().toList();
      expect(plays.last.card, equals(accepted));
    });

    test('submits exactly one command when first card is accepted', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const TrickPlayPhaseViewDto()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, hasLength(1));
    });
  });

  group('RandomAi — other phases', () {
    test('submits nothing during AllPassPhaseViewDto', () {
      final session = _FakeSession(
        view: _view(isMyTurn: true, phase: const AllPassPhaseViewDto()),
      );
      RandomAi(_id, session, Random(0)).onChanged();
      expect(session.commands, isEmpty);
    });
  });
}
