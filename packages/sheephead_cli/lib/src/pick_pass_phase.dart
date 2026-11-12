import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'pick_phase_label.dart';
import 'table_layout.dart';

class PickPassPhase with TableLayout, PickPhaseLabel implements GamePhase {
  PickPassPhase(this._playerId);

  final PlayerId _playerId;

  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    if (view.hand.isNotEmpty) {
      buffer.writeln(center(handLine(view.hand)));
      buffer.writeln();
    }

    buffer.write(center('Would you like to pick? [y/N]'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    switch (input.trim().toLowerCase()) {
      case 'y':
        return Submit(PickCommand(_playerId));
      case 'n':
      case '':
        return Submit(PassCommand(_playerId));
      default:
        return const Unrecognized();
    }
  }
}
