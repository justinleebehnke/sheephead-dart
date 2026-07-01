import 'package:sheephead_engine/sheephead_engine.dart';

import 'bury_selection.dart';
import 'game_phase.dart';
import 'parse_result.dart';
import 'pick_phase_label.dart';
import 'table_layout.dart';

class BuryPhase with TableLayout, PickPhaseLabel implements GamePhase {
  BuryPhase(this._selection);

  final BurySelection _selection;
  List<Card> _hand = [];
  bool _chopAllowed = false;

  @override
  String buildContent(PlayerView view) {
    _hand = view.hand;
    _chopAllowed = view.isChopAllowed;

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

    buffer.write(center('Bury 2 cards (e.g. 1,3):'));

    return buffer.toString();
  }

  @override
  ParseResult interpret(String input) {
    final parts = input.trim().split(',');
    if (parts.length != 2) return const Unrecognized();

    final a = int.tryParse(parts[0].trim());
    final b = int.tryParse(parts[1].trim());
    if (a == null || b == null) return const Unrecognized();
    if (a == b) return const Unrecognized();
    if (a < 1 || a > _hand.length) return const Unrecognized();
    if (b < 1 || b > _hand.length) return const Unrecognized();

    final cards = [_hand[a - 1], _hand[b - 1]];

    if (_chopAllowed) {
      _selection.cards = cards;
      return const Advance();
    }

    return Submit(BuryCommand(cards: cards, chop: false));
  }
}
