import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'table_layout.dart';

class StealPhase with TableLayout implements GamePhase {
  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    if (view.hand.isNotEmpty) {
      buffer.writeln(center(handLine(view.hand)));
      buffer.writeln();
    }

    buffer.write(center('Would you like to steal? [y/N]'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    switch (input.trim().toLowerCase()) {
      case 'y':
        return const Submit(StealCommand());
      case 'n':
      case '':
        return const Submit(DeclineStealCommand());
      default:
        return const Unrecognized();
    }
  }
}
