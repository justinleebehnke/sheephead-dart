import 'card.dart';
import 'player_id.dart';
import 'trick_resolver.dart';

enum InternalPhase {
  pick,
  allPass,
  bury,
  steal,
  trickPlay,
  trickResult,
  handResult,
  gameResult,
}

class CompletedTrick {
  const CompletedTrick({required this.winnerIndex, required this.trickPoints});
  final int winnerIndex;
  final int trickPoints;
}

class MasterGameState {
  const MasterGameState({
    this.hands = const {},
    this.blind = const [],
    this.dealerIndex = 0,
    this.currentPickerTurnIndex = 0,
    this.isDealt = false,
    this.passedIndices = const <int>{},
    this.pickerIndex,
    this.internalPhase = InternalPhase.pick,
    this.buriedCards = const [],
    this.isPickerGoingAlone = false,
    this.partnerIndex,
    this.currentLeaderIndex = 0,
    this.currentTrick = const [],
    this.completedTricks = const [],
  });

  final Map<PlayerId, List<Card>> hands;
  final List<Card> blind;
  final int dealerIndex;
  final int currentPickerTurnIndex;
  final bool isDealt;
  final Set<int> passedIndices;
  final int? pickerIndex;
  final InternalPhase internalPhase;
  final List<Card> buriedCards;
  final bool isPickerGoingAlone;
  final int? partnerIndex;
  final int currentLeaderIndex;
  final List<TrickPlay> currentTrick;
  final List<CompletedTrick> completedTricks;
}
