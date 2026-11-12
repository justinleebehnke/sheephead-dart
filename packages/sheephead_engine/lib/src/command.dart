import 'card.dart';
import 'player_id.dart';

sealed class Command {
  const Command();
}

final class PassCommand extends Command {
  const PassCommand(this.playerId);
  final PlayerId playerId;
}

final class PickCommand extends Command {
  const PickCommand(this.playerId);
  final PlayerId playerId;
}

final class BuryCommand extends Command {
  const BuryCommand({
    required this.playerId,
    required this.cards,
    required this.chop,
  });
  final PlayerId playerId;
  final List<Card> cards;
  final bool chop;
}

final class StealCommand extends Command {
  const StealCommand();
}

final class DeclineStealCommand extends Command {
  const DeclineStealCommand();
}

final class PlayCardCommand extends Command {
  const PlayCardCommand({required this.playerId, required this.card});
  final PlayerId playerId;
  final Card card;
}
