import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.interface.dart';
import 'parse_result.dart';
import 'pick_phase_label.dart';
import 'table_layout.dart';

class StealPhase with TableLayout, PickPhaseLabel implements IGamePhase {
  @override
  String buildContent(PlayerViewDto view) {
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
        return const Submit(StealCommandDto());
      case 'n':
      case '':
        return const Submit(DeclineStealCommandDto());
      default:
        return const Unrecognized();
    }
  }
}
