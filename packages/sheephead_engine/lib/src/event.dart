import 'card.dart';
import 'player_id.dart';

sealed class Event {
  const Event();
}

final class HandDealtEvent extends Event {
  const HandDealtEvent({
    required this.hands,
    required this.blind,
    required this.dealerIndex,
  });

  final Map<PlayerId, List<Card>> hands;
  final List<Card> blind;
  final int dealerIndex;
}

final class PlayerPassedEvent extends Event {
  const PlayerPassedEvent(this.playerId);
  final PlayerId playerId;
}

final class PlayerPickedEvent extends Event {
  const PlayerPickedEvent(this.playerId);
  final PlayerId playerId;
}

final class CardPlayedEvent extends Event {
  const CardPlayedEvent({required this.playerId, required this.card});
  final PlayerId playerId;
  final Card card;
}

final class CardsBuriedEvent extends Event {
  const CardsBuriedEvent({
    required this.playerId,
    required this.cards,
    required this.isGoingAlone,
  });
  final PlayerId playerId;
  final List<Card> cards;
  final bool isGoingAlone;
}
