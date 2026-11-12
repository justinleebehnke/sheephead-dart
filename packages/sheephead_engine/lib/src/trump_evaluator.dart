import 'card.dart';

class TrumpEvaluator {
  static bool isTrump(Card card) =>
      card.rank == Rank.queen ||
      card.rank == Rank.jack ||
      card.suit == Suit.diamonds;

  // Higher rank = stronger trump. Returns null for non-trump.
  static int? trumpRank(Card card) {
    if (!isTrump(card)) return null;
    if (card.rank == Rank.queen) {
      return switch (card.suit) {
        Suit.clubs => 13,
        Suit.spades => 11,
        Suit.hearts => 10,
        Suit.diamonds => 9,
      };
    }
    if (card.rank == Rank.jack) {
      return switch (card.suit) {
        Suit.clubs => 8,
        Suit.spades => 7,
        Suit.hearts => 6,
        Suit.diamonds => 5,
      };
    }
    // Diamond pip cards. 7♦ is rank 12 in Spitzer (2nd highest trump).
    return switch (card.rank) {
      Rank.seven => 12,
      Rank.ace => 4,
      Rank.ten => 3,
      Rank.king => 2,
      Rank.nine => 1,
      Rank.eight => 0,
      _ => null,
    };
  }

  // Higher rank = stronger within a fail suit.
  static int failRank(Card card) => switch (card.rank) {
    Rank.ace => 4,
    Rank.ten => 3,
    Rank.king => 2,
    Rank.nine => 1,
    _ => 0,
  };

  static int cardPoints(Card card) => switch (card.rank) {
    Rank.ace => 11,
    Rank.ten => 10,
    Rank.king => 4,
    Rank.queen => 3,
    Rank.jack => 2,
    _ => 0,
  };
}
