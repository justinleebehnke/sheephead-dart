import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  group('TrumpEvaluator.isTrump', () {
    test('all queens are trump', () {
      for (final suit in Suit.values) {
        expect(TrumpEvaluator.isTrump(Card(suit, Rank.queen)), isTrue);
      }
    });

    test('all jacks are trump', () {
      for (final suit in Suit.values) {
        expect(TrumpEvaluator.isTrump(Card(suit, Rank.jack)), isTrue);
      }
    });

    test('all diamonds are trump', () {
      for (final rank in Rank.values) {
        expect(TrumpEvaluator.isTrump(Card(Suit.diamonds, rank)), isTrue);
      }
    });

    test('non-queen non-jack non-diamond cards are not trump', () {
      for (final suit in [Suit.clubs, Suit.spades, Suit.hearts]) {
        for (final rank in [Rank.ace, Rank.ten, Rank.king, Rank.nine]) {
          expect(
            TrumpEvaluator.isTrump(Card(suit, rank)),
            isFalse,
            reason: '${Card(suit, rank).label} should not be trump',
          );
        }
      }
    });
  });

  group('TrumpEvaluator.trumpRank — Spitzer order', () {
    test('Q♣ is the highest trump', () {
      expect(
        TrumpEvaluator.trumpRank(const Card(Suit.clubs, Rank.queen)),
        equals(13),
      );
    });

    test('7♦ is second-highest trump (Spitzer special)', () {
      expect(
        TrumpEvaluator.trumpRank(const Card(Suit.diamonds, Rank.seven)),
        equals(12),
      );
    });

    test('7♦ outranks Q♠', () {
      expect(
        TrumpEvaluator.trumpRank(const Card(Suit.diamonds, Rank.seven))!,
        greaterThan(
          TrumpEvaluator.trumpRank(const Card(Suit.spades, Rank.queen))!,
        ),
      );
    });

    test('8♦ is the lowest trump', () {
      expect(
        TrumpEvaluator.trumpRank(const Card(Suit.diamonds, Rank.eight)),
        equals(0),
      );
    });

    test('full trump order is strictly descending', () {
      const trumpOrder = [
        Card(Suit.clubs, Rank.queen), // 13
        Card(Suit.diamonds, Rank.seven), // 12
        Card(Suit.spades, Rank.queen), // 11
        Card(Suit.hearts, Rank.queen), // 10
        Card(Suit.diamonds, Rank.queen), // 9
        Card(Suit.clubs, Rank.jack), // 8
        Card(Suit.spades, Rank.jack), // 7
        Card(Suit.hearts, Rank.jack), // 6
        Card(Suit.diamonds, Rank.jack), // 5
        Card(Suit.diamonds, Rank.ace), // 4
        Card(Suit.diamonds, Rank.ten), // 3
        Card(Suit.diamonds, Rank.king), // 2
        Card(Suit.diamonds, Rank.nine), // 1
        Card(Suit.diamonds, Rank.eight), // 0
      ];
      for (var i = 0; i < trumpOrder.length - 1; i++) {
        expect(
          TrumpEvaluator.trumpRank(trumpOrder[i])!,
          greaterThan(TrumpEvaluator.trumpRank(trumpOrder[i + 1])!),
          reason:
              '${trumpOrder[i].label} should rank higher than ${trumpOrder[i + 1].label}',
        );
      }
    });

    test('non-trump card returns null trump rank', () {
      expect(
        TrumpEvaluator.trumpRank(const Card(Suit.clubs, Rank.ace)),
        isNull,
      );
    });
  });

  group('TrumpEvaluator.cardPoints', () {
    test('ace is worth 11', () {
      expect(
        TrumpEvaluator.cardPoints(const Card(Suit.clubs, Rank.ace)),
        equals(11),
      );
    });

    test('ten is worth 10', () {
      expect(
        TrumpEvaluator.cardPoints(const Card(Suit.hearts, Rank.ten)),
        equals(10),
      );
    });

    test('king is worth 4', () {
      expect(
        TrumpEvaluator.cardPoints(const Card(Suit.spades, Rank.king)),
        equals(4),
      );
    });

    test('queen is worth 3', () {
      expect(
        TrumpEvaluator.cardPoints(const Card(Suit.clubs, Rank.queen)),
        equals(3),
      );
    });

    test('jack is worth 2', () {
      expect(
        TrumpEvaluator.cardPoints(const Card(Suit.diamonds, Rank.jack)),
        equals(2),
      );
    });

    test('nine eight seven are worth 0', () {
      for (final rank in [Rank.nine, Rank.eight, Rank.seven]) {
        expect(TrumpEvaluator.cardPoints(Card(Suit.clubs, rank)), equals(0));
      }
    });

    test('all 26 Spitzer cards total 120 points', () {
      final total = DeckComposition.spitzer().cards.fold<int>(
        0,
        (sum, c) => sum + TrumpEvaluator.cardPoints(c),
      );
      expect(total, equals(120));
    });
  });
}
