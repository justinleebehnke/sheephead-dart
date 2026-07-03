import 'card.dart';
import 'phase_view.dart';
import 'player_id.dart';
import 'seated_player.dart';

class PlayerView {
  const PlayerView({
    required this.id,
    required this.hand,
    required this.opponents,
    required this.isMyTurnToAct,
    required this.phase,
    this.isDoublesHand = false,
    this.isIDealer = false,
    this.isIPicker = false,
    this.isIGoingAlone = false,
    this.isIPartner = false,
  });

  final PlayerId id;
  final List<Card> hand;

  final List<SeatedPlayer> opponents;

  final bool isMyTurnToAct;
  final PhaseView phase;
  final bool isDoublesHand;
  final bool isIDealer;
  final bool isIPicker;
  final bool isIGoingAlone;
  final bool isIPartner;
}
