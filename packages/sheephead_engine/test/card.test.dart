import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  test('cards with same suit and rank are equal', () {
    const cardA = Card(Suit.clubs, Rank.queen);
    const cardB = Card(Suit.clubs, Rank.queen);

    expect(cardA, equals(cardB));
  });

  test('non-identical cards with same suit and rank are equal', () {
    // ignore: prefer_const_constructors
    final cardA = Card(Suit.clubs, Rank.queen);
    // ignore: prefer_const_constructors
    final cardB = Card(Suit.clubs, Rank.queen);

    expect(identical(cardA, cardB), isFalse);
    expect(cardA, equals(cardB));
  });

  test('cards with same suit and rank have equal hash codes', () {
    const cardA = Card(Suit.diamonds, Rank.seven);
    const cardB = Card(Suit.diamonds, Rank.seven);

    expect(cardA.hashCode, equals(cardB.hashCode));
  });

  group('label', () {
    test('uses rank abbreviation and suit symbol', () {
      expect(const Card(Suit.clubs, Rank.queen).label, 'Q♣');
      expect(const Card(Suit.diamonds, Rank.seven).label, '7♦');
      expect(const Card(Suit.spades, Rank.jack).label, 'J♠');
      expect(const Card(Suit.hearts, Rank.ten).label, '10♥');
      expect(const Card(Suit.clubs, Rank.ace).label, 'A♣');
      expect(const Card(Suit.diamonds, Rank.king).label, 'K♦');
      expect(const Card(Suit.spades, Rank.nine).label, '9♠');
      expect(const Card(Suit.hearts, Rank.eight).label, '8♥');
    });
  });

  test('cards with different suit or rank are not equal', () {
    const cardA = Card(Suit.hearts, Rank.ten);
    const cardB = Card(Suit.spades, Rank.ten);
    const cardC = Card(Suit.hearts, Rank.jack);

    expect(cardA, isNot(equals(cardB)));
    expect(cardA, isNot(equals(cardC)));
  });
}
