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
    this.cardPlayed,
  });

  final PlayerId id;
  final RelativeSeat seat;
  final bool isPassed;
  final bool isDealer;
  final bool isPicker;
  final bool isGoingAlone;
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
      other.cardPlayed == cardPlayed;

  @override
  int get hashCode => Object.hash(
    id,
    seat,
    isPassed,
    isDealer,
    isPicker,
    isGoingAlone,
    cardPlayed,
  );
}
