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
    return '${center(label(across))}\n\n${leftRight(label(left), label(right))}';
  }

  String handLine(List<Card> hand) => hand.map((c) => c.label).join(', ');

  String label(SeatedPlayer p) {
    final buf = StringBuffer('Player ${p.id.value}');
    if (p.isDealer) buf.write(' (D)');
    if (p.isPassed) buf.write(' passed');
    return buf.toString();
  }

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
