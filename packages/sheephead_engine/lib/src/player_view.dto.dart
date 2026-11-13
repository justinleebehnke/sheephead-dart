import 'card.dart';
import 'master_game_state.dart';
import 'phase_view.dto.dart';
import 'player_id.dart';
import 'seated_player.dart';

PlayerViewDto deriveViewDto(MasterGameState state, PlayerId viewerId) {
  final hand = state.hands[viewerId] ?? const <Card>[];

  return PlayerViewDto(
    id: viewerId,
    hand: List<Card>.unmodifiable(hand),
    opponents: const [],
    isMyTurnToAct: false,
    phase: const PickPhaseViewDto(),
  );
}

class PlayerViewDto {
  const PlayerViewDto({
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
  final PhaseViewDto phase;
  final bool isDoublesHand;
  final bool isIDealer;
  final bool isIPicker;
  final bool isIGoingAlone;
  final bool isIPartner;
}
