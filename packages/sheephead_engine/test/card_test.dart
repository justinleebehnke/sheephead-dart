import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  test('cards with same suit and rank are equal', () {
    const cardA = Card(Suit.clubs, Rank.queen);
    const cardB = Card(Suit.clubs, Rank.queen);

    expect(cardA, equals(cardB));
  });

  test('cards with same suit and rank have equal hash codes', () {
    const cardA = Card(Suit.diamonds, Rank.seven);
    const cardB = Card(Suit.diamonds, Rank.seven);

    expect(cardA.hashCode, equals(cardB.hashCode));
  });

  test('cards with different suit or rank are not equal', () {
    const cardA = Card(Suit.hearts, Rank.ten);
    const cardB = Card(Suit.spades, Rank.ten);
    const cardC = Card(Suit.hearts, Rank.jack);

    expect(cardA, isNot(equals(cardB)));
    expect(cardA, isNot(equals(cardC)));
  });
}
