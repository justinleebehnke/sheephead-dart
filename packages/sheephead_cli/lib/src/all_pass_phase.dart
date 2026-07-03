import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'pick_phase_label.dart';
import 'table_layout.dart';

class AllPassPhase with TableLayout, PickPhaseLabel implements GamePhase {
  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    buffer.writeln(center('Everyone passed — redealing as a doubles hand.'));
    buffer.writeln();

    buffer.write(center('Press Enter to continue'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    if (input.trim().isEmpty) return const Advance();
    return const Unrecognized();
  }
}
