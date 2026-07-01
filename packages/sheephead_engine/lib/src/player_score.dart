import 'player_id.dart';

class PlayerScore {
  const PlayerScore({
    required this.id,
    required this.handPoints,
    required this.runningTotal,
  });

  final PlayerId id;
  final int handPoints;
  final int runningTotal;

  @override
  bool operator ==(Object other) =>
      other is PlayerScore &&
      other.id == id &&
      other.handPoints == handPoints &&
      other.runningTotal == runningTotal;

  @override
  int get hashCode => Object.hash(id, handPoints, runningTotal);
}
