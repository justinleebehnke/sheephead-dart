import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_observer.dart';

abstract interface class GameSession {
  void addObserver(GameObserver observer);
  void removeObserver(GameObserver observer);
  PlayerView viewFor(PlayerId id);
  CommandResult submit(Command command);
}
