import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  const player = SeatedPlayer(
    id: PlayerId(1),
    seat: RelativeSeat.left,
    isPassed: false,
    isDealer: false,
    isPicker: false,
    isGoingAlone: false,
    cardPlayed: null,
  );

  test('seated players with same fields are equal', () {
    expect(
      player,
      const SeatedPlayer(
        id: PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: false,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: null,
      ),
    );
  });

  test('seated players with same fields have equal hash codes', () {
    expect(
      player.hashCode,
      const SeatedPlayer(
        id: PlayerId(1),
        seat: RelativeSeat.left,
        isPassed: false,
        isDealer: false,
        isPicker: false,
        isGoingAlone: false,
        cardPlayed: null,
      ).hashCode,
    );
  });

  test('seated players differ when id differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(2),
          seat: RelativeSeat.left,
          isPassed: false,
          isDealer: false,
          isPicker: false,
          isGoingAlone: false,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when seat differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.across,
          isPassed: false,
          isDealer: false,
          isPicker: false,
          isGoingAlone: false,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when isPassed differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.left,
          isPassed: true,
          isDealer: false,
          isPicker: false,
          isGoingAlone: false,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when isDealer differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.left,
          isPassed: false,
          isDealer: true,
          isPicker: false,
          isGoingAlone: false,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when isPicker differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.left,
          isPassed: false,
          isDealer: false,
          isPicker: true,
          isGoingAlone: false,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when isGoingAlone differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.left,
          isPassed: false,
          isDealer: false,
          isPicker: false,
          isGoingAlone: true,
          cardPlayed: null,
        ),
      ),
    );
  });

  test('seated players differ when cardPlayed differs', () {
    expect(
      player,
      isNot(
        const SeatedPlayer(
          id: PlayerId(1),
          seat: RelativeSeat.left,
          isPassed: false,
          isDealer: false,
          isPicker: false,
          isGoingAlone: false,
          cardPlayed: Card(Suit.clubs, Rank.queen),
        ),
      ),
    );
  });
}
