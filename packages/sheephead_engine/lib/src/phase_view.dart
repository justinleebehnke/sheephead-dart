import 'card.dart';
import 'player_id.dart';
import 'player_score.dart';

sealed class PhaseView {
  const PhaseView();
}

class PickPhaseView extends PhaseView {
  const PickPhaseView();
}

class AllPassPhaseView extends PhaseView {
  const AllPassPhaseView();
}

class BuryPhaseView extends PhaseView {
  const BuryPhaseView({required this.isChopAllowed});

  final bool isChopAllowed;
}

class StealPhaseView extends PhaseView {
  const StealPhaseView();
}

class TrickPlayPhaseView extends PhaseView {
  const TrickPlayPhaseView({this.leadSuit});
  final Suit? leadSuit;
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

class GameResultPhaseView extends PhaseView {
  const GameResultPhaseView({
    required this.standings,
    this.endedOnPassedOutHand = false,
  });

  final List<PlayerScore> standings;
  final bool endedOnPassedOutHand;
}
