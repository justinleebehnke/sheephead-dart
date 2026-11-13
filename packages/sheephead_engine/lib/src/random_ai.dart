import 'dart:math';

import 'command.dto.dart';
import 'command_result.dto.dart';
import 'game_observer.interface.dart';
import 'game_session.interface.dart';
import 'phase_view.dto.dart';
import 'player_id.dart';

final class RandomAi implements IGameObserver {
  RandomAi(this._id, this._session, this._random);

  final PlayerId _id;
  final IGameSession _session;
  final Random _random;

  @override
  void onChanged() {
    final view = _session.viewFor(_id);
    if (!view.isMyTurnToAct) return;

    switch (view.phase) {
      case PickPhaseViewDto():
        _session.submit(PassCommandDto(_id));
      case TrickPlayPhaseViewDto():
        final hand = List.of(view.hand)..shuffle(_random);
        for (final card in hand) {
          if (_session.submit(PlayCardCommandDto(playerId: _id, card: card))
              is Accepted) {
            break;
          }
        }
      default:
    }
  }
}
