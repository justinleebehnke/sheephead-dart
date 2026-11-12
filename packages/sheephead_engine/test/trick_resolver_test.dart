import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  group('TrickResolver.winner', () {
    test('highest trump wins a trump-led trick', () {
      // 7♦ leads; Q♣ played later but ranks highest
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.diamonds, Rank.seven)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.clubs, Rank.queen)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.hearts, Rank.jack)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.diamonds, Rank.eight)),
      ];
      expect(TrickResolver.winner(trick), equals(1));
    });

    test('any trump beats a fail-led trick', () {
      // A♣ leads (fail); 8♦ is lowest trump but still wins
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.clubs, Rank.ace)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.clubs, Rank.king)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.diamonds, Rank.eight)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.clubs, Rank.nine)),
      ];
      expect(TrickResolver.winner(trick), equals(2));
    });

    test('highest trump wins when multiple trump played on fail lead', () {
      // A♠ leads; 8♦ and Q♣ both trump — Q♣ wins
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.spades, Rank.ace)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.diamonds, Rank.eight)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.clubs, Rank.queen)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.spades, Rank.king)),
      ];
      expect(TrickResolver.winner(trick), equals(2));
    });

    test('highest fail card of led suit wins when no trump played', () {
      // K♥ leads; 10♥ outranks it; A♣ is a slough and cannot win
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.hearts, Rank.king)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.hearts, Rank.ten)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.clubs, Rank.ace)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.hearts, Rank.nine)),
      ];
      expect(TrickResolver.winner(trick), equals(1));
    });

    test('lead card wins when everyone else sloughs', () {
      // 9♥ leads; everyone else plays off-suit and off-trump
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.hearts, Rank.nine)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.clubs, Rank.ace)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.spades, Rank.ten)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.clubs, Rank.king)),
      ];
      expect(TrickResolver.winner(trick), equals(0));
    });

    test('7♦ beats all queens except Q♣', () {
      // Q♠ leads as trump; 7♦ beats it
      final trick = [
        TrickPlay(playerIndex: 0, card: const Card(Suit.spades, Rank.queen)),
        TrickPlay(playerIndex: 1, card: const Card(Suit.diamonds, Rank.seven)),
        TrickPlay(playerIndex: 2, card: const Card(Suit.hearts, Rank.queen)),
        TrickPlay(playerIndex: 3, card: const Card(Suit.diamonds, Rank.ace)),
      ];
      expect(TrickResolver.winner(trick), equals(1));
    });
  });
}
