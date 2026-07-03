import 'card.dart';
import 'player_id.dart';
import 'player_score.dart';

sealed class PhaseView {
  const PhaseView();
}

class PickPhaseView extends PhaseView {
  const PickPhaseView();
}

class BuryPhaseView extends PhaseView {
  const BuryPhaseView({required this.isChopAllowed});

  final bool isChopAllowed;
}

class StealPhaseView extends PhaseView {
  const StealPhaseView();
}

class TrickPlayPhaseView extends PhaseView {
  const TrickPlayPhaseView();
}

class TrickResultPhaseView extends PhaseView {
  const TrickResultPhaseView({
    required this.cardPlayed,
    required this.trickWinnerId,
  });

  final Card cardPlayed;
  final PlayerId trickWinnerId;
}

class HandResultPhaseView extends PhaseView {
  const HandResultPhaseView({required this.results});

  final List<PlayerScore> results;
}
