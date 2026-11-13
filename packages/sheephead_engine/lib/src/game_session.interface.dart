import 'command.dto.dart';
import 'command_result.dto.dart';
import 'game_observer.interface.dart';
import 'player_id.dart';
import 'player_view.dto.dart';

abstract interface class IGameSession {
  void addObserver(IGameObserver observer);
  void removeObserver(IGameObserver observer);
  PlayerViewDto viewFor(PlayerId id);
  CommandResultDto submit(CommandDto command);
}
