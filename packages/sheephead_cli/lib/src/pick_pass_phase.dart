import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_phase.dart';
import 'parse_result.dart';

class PickPassPhase implements GamePhase {
  @override
  String buildContent(PlayerView view) {
    final left = view.opponents.firstWhere((o) => o.seat == RelativeSeat.left);
    final across = view.opponents.firstWhere(
      (o) => o.seat == RelativeSeat.across,
    );
    final right = view.opponents.firstWhere(
      (o) => o.seat == RelativeSeat.right,
    );

    final buffer = StringBuffer();

    buffer.writeln(_center(_label(across)));
    buffer.writeln();

    buffer.writeln(_leftRight(_label(left), _label(right)));
    buffer.writeln();

    if (view.hand.isNotEmpty) {
      buffer.writeln(_center(view.hand.map((c) => c.label).join(', ')));
      buffer.writeln();
    }
    buffer.write(_center('Would you like to pick? [y/N]'));

    return buffer.toString();
  }

  String _label(SeatedPlayer p) {
    final buf = StringBuffer('Player ${p.id.value}');
    if (p.isDealer) buf.write(' (D)');
    if (p.isPassed) buf.write(' passed');
    return buf.toString();
  }

  String _center(String s, {int width = 80}) {
    if (s.length >= width) return s;
    return ' ' * ((width - s.length) ~/ 2) + s;
  }

  String _leftRight(String left, String right, {int width = 80}) {
    final gap = width - left.length - right.length;
    if (gap < 1) return '$left $right';
    return '$left${' ' * gap}$right';
  }

  @override
  ParseResult interpret(String input) {
    switch (input.trim().toLowerCase()) {
      case 'y':
        return const Submit(PickCommand());
      case 'n':
      case '':
        return const Submit(PassCommand());
      default:
        return const Unrecognized();
    }
  }
}
