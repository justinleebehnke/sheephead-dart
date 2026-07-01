import 'package:sheephead_engine/sheephead_engine.dart';

import 'parse_result.dart';

abstract interface class GamePhase {
  String buildContent(PlayerView view);
  ParseResult interpret(String input);
}
