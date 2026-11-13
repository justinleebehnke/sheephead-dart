import 'card.dart';
import 'player_id.dart';

sealed class CommandDto {
  const CommandDto();
}

final class PassCommandDto extends CommandDto {
  const PassCommandDto(this.playerId);
  final PlayerId playerId;
}

final class PickCommandDto extends CommandDto {
  const PickCommandDto(this.playerId);
  final PlayerId playerId;
}

final class BuryCommandDto extends CommandDto {
  const BuryCommandDto({
    required this.playerId,
    required this.cards,
    required this.chop,
  });
  final PlayerId playerId;
  final List<Card> cards;
  final bool chop;
}

final class StealCommandDto extends CommandDto {
  const StealCommandDto();
}

final class DeclineStealCommandDto extends CommandDto {
  const DeclineStealCommandDto();
}

final class PlayCardCommandDto extends CommandDto {
  const PlayCardCommandDto({required this.playerId, required this.card});
  final PlayerId playerId;
  final Card card;
}
