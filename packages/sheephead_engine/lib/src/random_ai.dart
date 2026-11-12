import 'dart:math';

import 'command.dart';
import 'command_result.dart';
import 'game_observer.dart';
import 'game_session.dart';
import 'phase_view.dart';
import 'player_id.dart';

final class RandomAi implements GameObserver {
  RandomAi(this._id, this._session, this._random);

  final PlayerId _id;
  final GameSession _session;
  final Random _random;

  @override
  void onChanged() {
    final view = _session.viewFor(_id);
    if (!view.isMyTurnToAct) return;

    switch (view.phase) {
      case PickPhaseView():
        _session.submit(PassCommand(_id));
      case TrickPlayPhaseView():
        final hand = List.of(view.hand)..shuffle(_random);
        for (final card in hand) {
          if (_session.submit(PlayCardCommand(playerId: _id, card: card))
              is Accepted) {
            break;
          }
        }
      default:
    }
  }
}
