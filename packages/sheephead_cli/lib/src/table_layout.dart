import 'package:sheephead_engine/sheephead_engine.dart';

mixin TableLayout {
  String opponentTable(PlayerView view) {
    final left = view.opponents.firstWhere((o) => o.seat == RelativeSeat.left);
    final across = view.opponents.firstWhere(
      (o) => o.seat == RelativeSeat.across,
    );
    final right = view.opponents.firstWhere(
      (o) => o.seat == RelativeSeat.right,
    );

    final buf = StringBuffer();
    buf.writeln(center(label(across)));
    if (across.cardPlayed != null) {
      buf.writeln(center(across.cardPlayed!.label));
    }
    buf.writeln();
    buf.write(leftRight(label(left), label(right)));
    final leftCard = left.cardPlayed?.label ?? '';
    final rightCard = right.cardPlayed?.label ?? '';
    if (leftCard.isNotEmpty || rightCard.isNotEmpty) {
      buf.writeln();
      buf.write(leftRight(leftCard, rightCard));
    }
    return buf.toString();
  }

  String handLine(List<Card> hand) => hand.map((c) => c.label).join(', ');

  String label(SeatedPlayer p);

  String center(String s, {int width = 80}) {
    if (s.length >= width) return s;
    return ' ' * ((width - s.length) ~/ 2) + s;
  }

  String leftRight(String left, String right, {int width = 80}) {
    final gap = width - left.length - right.length;
    if (gap < 1) return '$left $right';
    return '$left${' ' * gap}$right';
  }
}
