import 'card.dart';
import 'player_id.dart';
import 'player_score.dart';

sealed class PhaseViewDto {
  const PhaseViewDto();
}

class PickPhaseViewDto extends PhaseViewDto {
  const PickPhaseViewDto();
}

class AllPassPhaseViewDto extends PhaseViewDto {
  const AllPassPhaseViewDto();
}

class BuryPhaseViewDto extends PhaseViewDto {
  const BuryPhaseViewDto({required this.isChopAllowed});

  final bool isChopAllowed;
}

class StealPhaseViewDto extends PhaseViewDto {
  const StealPhaseViewDto();
}

class TrickPlayPhaseViewDto extends PhaseViewDto {
  const TrickPlayPhaseViewDto({this.leadSuit});
  final Suit? leadSuit;
}

class TrickResultPhaseViewDto extends PhaseViewDto {
  const TrickResultPhaseViewDto({
    required this.cardPlayed,
    required this.trickWinnerId,
  });

  final Card cardPlayed;
  final PlayerId trickWinnerId;
}

class HandResultPhaseViewDto extends PhaseViewDto {
  const HandResultPhaseViewDto({required this.results});

  final List<PlayerScore> results;
}

class GameResultPhaseViewDto extends PhaseViewDto {
  const GameResultPhaseViewDto({
    required this.standings,
    this.endedOnPassedOutHand = false,
  });

  final List<PlayerScore> standings;
  final bool endedOnPassedOutHand;
}
