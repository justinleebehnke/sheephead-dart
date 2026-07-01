import 'package:sheephead_engine/sheephead_engine.dart';

mixin TrickPhaseLabel {
  String label(SeatedPlayer p) {
    final buf = StringBuffer('Player ${p.id.value}');
    if (p.isDealer) buf.write(' (D)');
    if (p.isStealer) {
      buf.write(' stole the blind');
    } else if (p.isRobbed) {
      buf.write(' picked (ally)');
    } else if (p.isPicker) {
      if (p.isGoingAlone) {
        buf.write(' picked (chop)');
      } else {
        buf.write(' picked');
      }
    }
    return buf.toString();
  }
}
