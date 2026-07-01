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

  String get label {
    final r = switch (rank) {
      Rank.seven => '7',
      Rank.eight => '8',
      Rank.nine => '9',
      Rank.ten => '10',
      Rank.jack => 'J',
      Rank.queen => 'Q',
      Rank.king => 'K',
      Rank.ace => 'A',
    };
    final s = switch (suit) {
      Suit.clubs => '♣',
      Suit.diamonds => '♦',
      Suit.spades => '♠',
      Suit.hearts => '♥',
    };
    return '$r$s';
  }

  @override
  String toString() => '${rank.name} of ${suit.name}';
}
