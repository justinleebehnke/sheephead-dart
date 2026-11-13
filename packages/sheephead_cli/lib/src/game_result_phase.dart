import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.interface.dart';
import 'parse_result.dart';
import 'table_layout.dart';
import 'trick_phase_label.dart';

class GameResultPhase with TableLayout, TrickPhaseLabel implements IGamePhase {
  @override
  String buildContent(PlayerViewDto view) {
    final phase = view.phase as GameResultPhaseViewDto;
    final standings = phase.standings;

    final buffer = StringBuffer();

    buffer.writeln(center('Game Over'));
    buffer.writeln();

    if (phase.endedOnPassedOutHand) {
      buffer.writeln(center('The final hand was passed out.'));
      buffer.writeln();
    }

    if (standings.isNotEmpty) {
      final topTotal = standings
          .map((s) => s.runningTotal)
          .reduce((a, b) => a > b ? a : b);

      for (final score in standings) {
        final name = score.id == view.id ? 'You' : 'Player ${score.id.value}';
        final total = _signed(score.runningTotal);
        final marker = score.runningTotal == topTotal ? '  (winner)' : '';
        buffer.writeln(center('$name    $total$marker'));
      }
      buffer.writeln();
    }

    buffer.writeln(center('Run the program again to play another game.'));
    buffer.writeln();
    buffer.write(center('Press Enter to exit'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    if (input.trim().isEmpty) return const Quit();
    return const Unrecognized();
  }

  String _signed(int n) => n >= 0 ? '+$n' : '$n';
}
