import 'card.dart';
import 'trump_evaluator.dart';

class TrickPlay {
  const TrickPlay({required this.playerIndex, required this.card});
  final int playerIndex;
  final Card card;
}

class TrickResolver {
  static int winner(List<TrickPlay> trick) {
    assert(trick.isNotEmpty);
    final leadCard = trick.first.card;
    final trumpLed = TrumpEvaluator.isTrump(leadCard);
    final failLeadSuit = trumpLed ? null : leadCard.suit;

    var bestIdx = 0;
    for (var i = 1; i < trick.length; i++) {
      if (_beats(trick[i].card, trick[bestIdx].card, trumpLed, failLeadSuit)) {
        bestIdx = i;
      }
    }
    return trick[bestIdx].playerIndex;
  }

  static bool _beats(
    Card challenger,
    Card defender,
    bool trumpLed,
    Suit? failLeadSuit,
  ) {
    final cTrump = TrumpEvaluator.isTrump(challenger);
    final dTrump = TrumpEvaluator.isTrump(defender);

    if (cTrump && dTrump) {
      return TrumpEvaluator.trumpRank(challenger)! >
          TrumpEvaluator.trumpRank(defender)!;
    }
    if (cTrump) return true;
    if (dTrump) return false;

    if (trumpLed) return false;

    if (challenger.suit == failLeadSuit && defender.suit != failLeadSuit) {
      return true;
    }
    if (challenger.suit != failLeadSuit) return false;
    return TrumpEvaluator.failRank(challenger) >
        TrumpEvaluator.failRank(defender);
  }
}
