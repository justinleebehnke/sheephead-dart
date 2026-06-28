enum Suit { clubs, diamonds, hearts, spades }

enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

class Card {
  final Suit suit;
  final Rank rank;

  const Card(this.suit, this.rank);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Card && other.suit == suit && other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '$rank of $suit';
}
