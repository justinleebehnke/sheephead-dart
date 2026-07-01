import 'card.dart';
import 'player_id.dart';
import 'relative_seat.dart';

class SeatedPlayer {
  const SeatedPlayer({
    required this.id,
    required this.seat,
    required this.isPassed,
    required this.isDealer,
    required this.isPicker,
    required this.isGoingAlone,
    this.isDeclinedSteal = false,
    this.isStealer = false,
    this.isRobbed = false,
    this.cardPlayed,
  });

  final PlayerId id;
  final RelativeSeat seat;
  final bool isPassed;
  final bool isDealer;
  final bool isPicker;
  final bool isGoingAlone;
  final bool isDeclinedSteal;
  final bool isStealer;
  final bool isRobbed;
  final Card? cardPlayed;

  @override
  bool operator ==(Object other) =>
      other is SeatedPlayer &&
      other.id == id &&
      other.seat == seat &&
      other.isPassed == isPassed &&
      other.isDealer == isDealer &&
      other.isPicker == isPicker &&
      other.isGoingAlone == isGoingAlone &&
      other.isDeclinedSteal == isDeclinedSteal &&
      other.isStealer == isStealer &&
      other.isRobbed == isRobbed &&
      other.cardPlayed == cardPlayed;

  @override
  int get hashCode => Object.hash(
    id,
    seat,
    isPassed,
    isDealer,
    isPicker,
    isGoingAlone,
    isDeclinedSteal,
    isStealer,
    isRobbed,
    cardPlayed,
  );
}
