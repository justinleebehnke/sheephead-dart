import 'card.dart';
import 'command.dart';

final class PlayCardCommand implements Command {
  const PlayCardCommand({required this.card});

  final Card card;
}
