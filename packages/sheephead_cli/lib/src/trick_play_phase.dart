import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';
import 'table_layout.dart';
import 'trick_phase_label.dart';

class TrickPlayPhase with TableLayout, TrickPhaseLabel implements GamePhase {
  List<Card> _hand = [];

  @override
  String buildContent(PlayerView view) {
    _hand = view.hand;

    final buffer = StringBuffer();

    buffer.writeln(opponentTable(view));
    buffer.writeln();

    if (view.hand.isNotEmpty) {
      final numbered = view.hand
          .asMap()
          .entries
          .map((e) => '${e.key + 1}:${e.value.label}')
          .join(', ');
      buffer.writeln(center(numbered));
      buffer.writeln();
    }

    buffer.write(center('Play a card (1-${view.hand.length}):'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    final n = int.tryParse(input.trim());
    if (n == null) return const Unrecognized();
    if (n < 1 || n > _hand.length) return const Unrecognized();
    return Submit(PlayCardCommand(card: _hand[n - 1]));
  }
}
