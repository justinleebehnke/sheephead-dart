import 'deck_composition.dart';

class GameConfig {
  const GameConfig({
    required this.playerCount,
    required this.handSize,
    required this.blindSize,
    required this.roundsPerGame,
    required this.deckComposition,
  });

  final int playerCount;
  final int handSize;
  final int blindSize;
  final int roundsPerGame;
  final DeckComposition deckComposition;

  static GameConfig spitzer4({int roundsPerGame = 4}) => GameConfig(
    playerCount: 4,
    handSize: 6,
    blindSize: 2,
    roundsPerGame: roundsPerGame,
    deckComposition: DeckComposition.spitzer(),
  );
}
