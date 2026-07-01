import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'table_layout.dart';
import 'trick_phase_label.dart';

class HandResultPhase with TableLayout, TrickPhaseLabel implements GamePhase {
  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(center('Hand Result'));
    buffer.writeln();

    final results = view.handResults;
    if (results != null && results.isNotEmpty) {
      final labels = results
          .map(
            (s) => s.id == view.id
                ? _selfLabel(view)
                : label(view.opponents.firstWhere((o) => o.id == s.id)),
          )
          .toList();

      final maxLabelLen = labels.fold(0, (m, l) => l.length > m ? l.length : m);

      for (var i = 0; i < results.length; i++) {
        final score = results[i];
        final hand = _signed(score.handPoints).padLeft(4);
        final total = '(total: ${_signed(score.runningTotal)})'.padLeft(14);
        final row = '${labels[i].padRight(maxLabelLen)}    $hand pts    $total';
        buffer.writeln(center(row));
      }
      buffer.writeln();
    }

    buffer.write(center('Press Enter to continue'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    if (input.trim().isEmpty) return const Advance();
    return const Unrecognized();
  }

  String _selfLabel(PlayerView view) {
    final buf = StringBuffer('Player ${view.id.value}');
    if (view.isIDealer) buf.write(' (D)');
    if (view.isIPicker) {
      if (view.isIGoingAlone) {
        buf.write(' picked (chop)');
      } else {
        buf.write(' picked');
      }
    }
    return buf.toString();
  }

  String _signed(int n) => n >= 0 ? '+$n' : '$n';
}
