import 'package:sheephead_engine/sheephead_engine.dart';

import 'parse_result.dart';

abstract interface class IGamePhase {
  String buildContent(PlayerViewDto view);
  ParseResult interpret(String input);
}
