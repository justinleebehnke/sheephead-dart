import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'table_layout.dart';
import 'trick_phase_label.dart';

class TrickResultPhase with TableLayout, TrickPhaseLabel implements GamePhase {
  @override
  String buildContent(PlayerView view) {
    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    if (view.cardPlayed != null) {
      buffer.writeln(center(view.cardPlayed!.label));
      buffer.writeln();
    }

    final winnerId = view.trickWinnerId;
    if (winnerId != null) {
      final winnerLabel = winnerId == view.id
          ? 'You win the trick!'
          : 'Player ${winnerId.value} wins the trick';
      buffer.writeln(center(winnerLabel));
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
}
