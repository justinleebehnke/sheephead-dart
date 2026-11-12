import 'card.dart';

class DeckComposition {
  const DeckComposition._(this.cards);

  final List<Card> cards;

  static DeckComposition spitzer() {
    final cards = <Card>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        if (suit != Suit.diamonds &&
            (rank == Rank.seven || rank == Rank.eight)) {
          continue;
        }
        cards.add(Card(suit, rank));
      }
    }
    return DeckComposition._(List.unmodifiable(cards));
  }
}
