import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late PickPassPhase phase;

  setUp(() => phase = PickPassPhase());

  PlayerView makeView({
    List<Card> hand = const [],
    bool leftPassed = false,
    bool acrossPassed = false,
    bool rightPassed = false,
    bool leftDealer = false,
    bool acrossDealer = false,
    bool rightDealer = false,
  }) => PlayerView(
    id: const PlayerId(0),
    hand: hand,
    opponents: [
      SeatedPlayer(
        id: const PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: leftPassed,
        isDealer: leftDealer,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(2),
        seat: RelativeSeat.across,
        isPassed: acrossPassed,
        isDealer: acrossDealer,
        isPicker: false,
        isGoingAlone: false,
      ),
      SeatedPlayer(
        id: const PlayerId(3),
        seat: RelativeSeat.right,
        isPassed: rightPassed,
        isDealer: rightDealer,
        isPicker: false,
        isGoingAlone: false,
      ),
    ],
    isMyTurnToAct: true,
  );

  group('buildContent', () {
    test('shows each opponent', () {
      final content = phase.buildContent(makeView());

      expect(content, contains('Player 1'));
      expect(content, contains('Player 2'));
      expect(content, contains('Player 3'));
    });

    test('shows across player above left and right players', () {
      final content = phase.buildContent(makeView());

      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 1')),
      );
      expect(
        content.indexOf('Player 2'),
        lessThan(content.indexOf('Player 3')),
      );
    });

    test('shows left and right players on the same line', () {
      final lines = phase.buildContent(makeView()).split('\n');

      expect(
        lines.any((l) => l.contains('Player 1') && l.contains('Player 3')),
        isTrue,
      );
    });

    test('shows opponents in relative seat order — left before right', () {
      final content = phase.buildContent(makeView());

      expect(
        content.indexOf('Player 1'),
        lessThan(content.indexOf('Player 3')),
      );
    });

    test('no line exceeds 80 characters', () {
      final content = phase.buildContent(
        makeView(
          hand: [
            const Card(Suit.clubs, Rank.queen),
            const Card(Suit.diamonds, Rank.jack),
          ],
        ),
      );

      for (final line in content.split('\n')) {
        expect(
          line.length,
          lessThanOrEqualTo(80),
          reason: 'Line too long: "$line"',
        );
      }
    });

    test('marks opponents who have passed', () {
      final content = phase.buildContent(
        makeView(leftPassed: true, acrossPassed: true),
      );

      expect(content, contains('Player 1 passed'));
      expect(content, contains('Player 2 passed'));
      expect(content, isNot(contains('Player 3 passed')));
    });

    test('marks the dealer', () {
      final content = phase.buildContent(makeView(rightDealer: true));

      final p3Index = content.indexOf('Player 3');
      expect(content.indexOf('(D)', p3Index), greaterThan(p3Index));
    });

    test('shows hand as comma-separated list with suit symbols', () {
      final content = phase.buildContent(
        makeView(
          hand: [
            const Card(Suit.clubs, Rank.queen),
            const Card(Suit.diamonds, Rank.jack),
          ],
        ),
      );

      expect(content, contains('Q♣, J♦'));
    });

    test('shows pick prompt with y/N default', () {
      expect(
        phase.buildContent(makeView()),
        contains('Would you like to pick? [y/N]'),
      );
    });

    test('centers the pick prompt', () {
      final lines = phase.buildContent(makeView()).split('\n');
      final promptLine = lines.firstWhere(
        (l) => l.contains('Would you like to pick?'),
      );
      expect(promptLine, startsWith(' '));
    });

    test('fills 80 columns on the left/right player row', () {
      final lines = phase.buildContent(makeView()).split('\n');
      final row = lines.firstWhere(
        (l) => l.contains('Player 1') && l.contains('Player 3'),
      );
      expect(row.length, 80);
    });
  });

  group('interpret', () {
    test('"y" submits a PickCommand', () {
      final result = phase.interpret('y');
      expect(result, isA<Submit>());
      expect((result as Submit).command, isA<PickCommand>());
    });

    test('"Y" submits a PickCommand', () {
      final result = phase.interpret('Y');
      expect(result, isA<Submit>());
      expect((result as Submit).command, isA<PickCommand>());
    });

    test('"n" submits a PassCommand', () {
      final result = phase.interpret('n');
      expect(result, isA<Submit>());
      expect((result as Submit).command, isA<PassCommand>());
    });

    test('"N" submits a PassCommand', () {
      final result = phase.interpret('N');
      expect(result, isA<Submit>());
      expect((result as Submit).command, isA<PassCommand>());
    });

    test('empty input submits a PassCommand (default)', () {
      final result = phase.interpret('');
      expect(result, isA<Submit>());
      expect((result as Submit).command, isA<PassCommand>());
    });

    test('unrecognized input returns Unrecognized', () {
      expect(phase.interpret('garbage'), isA<Unrecognized>());
    });
  });
}
