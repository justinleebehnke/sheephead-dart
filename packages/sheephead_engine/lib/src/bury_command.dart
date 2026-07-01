import 'card.dart';
import 'command.dart';

final class BuryCommand implements Command {
  const BuryCommand({required this.cards, required this.chop});

  final List<Card> cards;
  final bool chop;
}
