import 'command.dart';
import 'command_result.dart';
import 'game_observer.dart';
import 'player_id.dart';
import 'player_view.dart';

abstract interface class GameSession {
  void addObserver(GameObserver observer);
  void removeObserver(GameObserver observer);
  PlayerView viewFor(PlayerId id);
  CommandResult submit(Command command);
}
