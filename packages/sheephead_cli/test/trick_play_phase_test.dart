import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late TrickPlayPhase phase;

  setUp(() {
    phase = TrickPlayPhase();
  });

  const hand = [
    Card(Suit.clubs, Rank.queen),
    Card(Suit.diamonds, Rank.seven),
    Card(Suit.hearts, Rank.ace),
    Card(Suit.spades, Rank.nine),
  ];

  PlayerView makeView({
    List<Card> hand = const [],
    Card? leftPlayed,
    Card? acrossPlayed,
    Card? rightPlayed,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: hand,
    opponents: [
      SeatedPlayer(
        id: const PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: true,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: leftPlayed,
      ),
      SeatedPlayer(
        id: const PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: false,
        isDealer: false,
        isPicker: true,
        isGoingAlone: false,
        cardPlayed: acrossPlayed,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: false,
        isDealer: true,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: rightPlayed,
      ),
    ],
    isMyTurnToAct: true,
  );

  group('buildContent', () {
    test('shows play prompt', () {
      expect(
        phase.buildContent(makeView(hand: hand)),
        contains('Play a card (1-4):'),
      );
    });

    test('shows each hand card with a number', () {
      final content = phase.buildContent(makeView(hand: hand));

      expect(content, contains('1:Q♣'));
      expect(content, contains('3:A♥'));
      expect(content, contains('4:9♠'));
    });

    test('shows all hand cards on one line', () {
      final lines = phase.buildContent(makeView(hand: hand)).split('\n');

      expect(
        lines.any((String l) => l.contains('1:Q♣') && l.contains('4:9♠')),
        isTrue,
      );
    });

    test('shows opponents in table layout', () {
      final content = phase.buildContent(makeView(hand: hand));

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
    });

    test('shows a card played by the across opponent', () {
      final content = phase.buildContent(
        makeView(acrossPlayed: const Card(Suit.diamonds, Rank.ten)),
      );

      expect(content, contains('10♦'));
    });

    test('across card appears below across player label', () {
      final content = phase.buildContent(
        makeView(acrossPlayed: const Card(Suit.diamonds, Rank.ten)),
      );

      expect(content.indexOf('Player 2'), lessThan(content.indexOf('10♦')));
    });

    test('shows a card played by the left opponent', () {
      final content = phase.buildContent(
        makeView(leftPlayed: const Card(Suit.spades, Rank.king)),
      );

      expect(content, contains('K♠'));
    });

    test('shows a card played by the right opponent', () {
      final content = phase.buildContent(
        makeView(rightPlayed: const Card(Suit.hearts, Rank.nine)),
      );

      expect(content, contains('9♥'));
    });

    test('shows no card line when no opponent has played', () {
      final lines = phase.buildContent(makeView()).split('\n');
      final cardLabels = ['♣', '♦', '♠', '♥'];

      expect(
        lines.any(
          (String l) => cardLabels.any(l.contains) && !l.contains('Player'),
        ),
        isFalse,
      );
    });
  });

  group('buildContent opponent labels during trick play', () {
    PlayerView viewWithOpponents({
      SeatedPlayer? left,
      SeatedPlayer? across,
      SeatedPlayer? right,
    }) => PlayerView(
      id: const PlayerId(0),
      hand: const [],
      opponents: [
        left ??
            SeatedPlayer(
              id: const PlayerId(1),
              seat: RelativeSeat.left,
              isPassed: true,
              isDealer: false,
              isPicker: false,
              isGoingAlone: false,
            ),
        across ??
            SeatedPlayer(
              id: const PlayerId(2),
              seat: RelativeSeat.across,
              isPassed: false,
              isDealer: false,
              isPicker: true,
              isGoingAlone: false,
            ),
        right ??
            SeatedPlayer(
              id: const PlayerId(3),
              seat: RelativeSeat.right,
              isPassed: false,
              isDealer: true,
              isPicker: false,
              isGoingAlone: false,
            ),
      ],
      isMyTurnToAct: true,
    );

    test('does not show passed status', () {
      expect(
        phase.buildContent(viewWithOpponents()),
        isNot(contains('passed')),
      );
    });

    test('does not show declined steal status', () {
      final content = phase.buildContent(
        viewWithOpponents(
          left: const SeatedPlayer(
            id: PlayerId(1),
            seat: RelativeSeat.left,
            isPassed: false,
            isDealer: false,
            isPicker: false,
            isGoingAlone: false,
            isDeclinedSteal: true,
          ),
        ),
      );

      expect(content, isNot(contains('declined steal')));
    });

    test('still shows dealer marker', () {
      expect(phase.buildContent(viewWithOpponents()), contains('Player 3 (D)'));
    });

    test('labels the picker', () {
      expect(
        phase.buildContent(viewWithOpponents()),
        contains('Player 2 picked'),
      );
    });

    test('labels the picker going alone as chop', () {
      final content = phase.buildContent(
        viewWithOpponents(
          across: const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: true,
            isGoingAlone: true,
          ),
        ),
      );

      expect(content, contains('Player 2 picked (chop)'));
    });

    test('labels the robbed picker as ally', () {
      final content = phase.buildContent(
        viewWithOpponents(
          across: const SeatedPlayer(
            id: PlayerId(2),
            seat: RelativeSeat.across,
            isPassed: false,
            isDealer: false,
            isPicker: true,
            isGoingAlone: false,
            isRobbed: true,
          ),
        ),
      );

      expect(content, contains('Player 2 picked (ally)'));
    });

    test('labels the stealer', () {
      final content = phase.buildContent(
        viewWithOpponents(
          left: const SeatedPlayer(
            id: PlayerId(1),
            seat: RelativeSeat.left,
            isPassed: false,
            isDealer: false,
            isPicker: false,
            isGoingAlone: true,
            isStealer: true,
          ),
        ),
      );

      expect(content, contains('Player 1 stole the blind'));
    });
  });

  group('interpret', () {
    setUp(() => phase.buildContent(makeView(hand: hand)));

    test('valid number submits PlayCardCommand with the correct card', () {
      final result = phase.interpret('1');

      expect(result, isA<Submit>());
      final cmd = (result as Submit).command as PlayCardCommand;
      expect(cmd.card, hand[0]);
    });

    test('"3" submits the third card', () {
      final cmd = (phase.interpret('3') as Submit).command as PlayCardCommand;

      expect(cmd.card, hand[2]);
    });

    test('index 0 is out of range', () {
      expect(phase.interpret('0'), isA<Unrecognized>());
    });

    test('index beyond hand size is out of range', () {
      expect(phase.interpret('5'), isA<Unrecognized>());
    });

    test('non-number is Unrecognized', () {
      expect(phase.interpret('ace'), isA<Unrecognized>());
    });

    test('empty input is Unrecognized', () {
      expect(phase.interpret(''), isA<Unrecognized>());
    });
  });
}
