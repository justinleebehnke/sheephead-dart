import 'package:sheephead_engine/sheephead_engine.dart';

import 'bury_selection.dart';
import 'game_phase.dart';
import 'parse_result.dart';
import 'pick_phase_label.dart';
import 'table_layout.dart';

class ChopPhase with TableLayout, PickPhaseLabel implements GamePhase {
  ChopPhase(this._selection);

  final BurySelection _selection;

  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    if (view.hand.isNotEmpty) {
      buffer.writeln(center(handLine(view.hand)));
      buffer.writeln();
    }

    buffer.write(center('Would you like to chop (go alone)? [y/N]'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    final cards = _selection.cards!;
    switch (input.trim().toLowerCase()) {
      case 'y':
        return Submit(BuryCommand(cards: cards, chop: true));
      case 'n':
      case '':
        return Submit(BuryCommand(cards: cards, chop: false));
      default:
        return const Unrecognized();
    }
  }
}
