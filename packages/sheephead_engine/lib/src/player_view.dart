import 'card.dart';
import 'player_id.dart';
import 'player_score.dart';
import 'seated_player.dart';

class PlayerView {
  const PlayerView({
    required this.id,
    required this.hand,
    required this.opponents,
    required this.isMyTurnToAct,
    this.isChopAllowed = false,
    this.isOfferedSteal = false,
    this.isIDealer = false,
    this.isIPicker = false,
    this.isIGoingAlone = false,
    this.cardPlayed,
    this.trickWinnerId,
    this.handResults,
  });

  final PlayerId id;
  final List<Card> hand;

  final List<SeatedPlayer> opponents;

  final bool isMyTurnToAct;
  final bool isChopAllowed;
  final bool isOfferedSteal;
  final bool isIDealer;
  final bool isIPicker;
  final bool isIGoingAlone;
  final Card? cardPlayed;
  final PlayerId? trickWinnerId;
  final List<PlayerScore>? handResults;
}
