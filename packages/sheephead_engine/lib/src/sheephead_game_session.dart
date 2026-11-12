import 'card.dart';
import 'command.dart';
import 'command_result.dart';
import 'event.dart';
import 'game_config.dart';
import 'game_observer.dart';
import 'game_session.dart';
import 'master_game_state.dart';
import 'phase_view.dart';
import 'player_id.dart';
import 'player_score.dart';
import 'player_view.dart';
import 'relative_seat.dart';
import 'seated_player.dart';
import 'shuffler.dart';
import 'trick_resolver.dart';
import 'trump_evaluator.dart';

final class SheepheadGameSession implements GameSession {
  SheepheadGameSession(GameConfig config, Shuffler shuffler)
    : _config = config {
    final required = config.playerCount * config.handSize + config.blindSize;
    final actual = config.deckComposition.cards.length;
    if (required != actual) {
      throw ArgumentError(
        'Deck has $actual cards but config requires $required '
        '(${config.playerCount} × ${config.handSize} + ${config.blindSize} blind).',
      );
    }
    _deal(shuffler, dealerIndex: 0);
  }

  final GameConfig _config;
  final List<GameObserver> _observers = [];
  MasterGameState _state = const MasterGameState();

  void _deal(Shuffler shuffler, {required int dealerIndex}) {
    final shuffled = shuffler.shuffle(_config.deckComposition.cards);
    final hands = <PlayerId, List<Card>>{};
    var offset = 0;
    for (var i = 0; i < _config.playerCount; i++) {
      hands[PlayerId(i)] = List.unmodifiable(
        shuffled.sublist(offset, offset + _config.handSize),
      );
      offset += _config.handSize;
    }
    final blind = List<Card>.unmodifiable(
      shuffled.sublist(offset, offset + _config.blindSize),
    );
    _state = _apply(
      _state,
      HandDealtEvent(hands: hands, blind: blind, dealerIndex: dealerIndex),
    );
    _notifyObservers();
  }

  MasterGameState _apply(MasterGameState state, Event event) {
    return switch (event) {
      HandDealtEvent e => MasterGameState(
        hands: e.hands,
        blind: e.blind,
        dealerIndex: e.dealerIndex,
        currentPickerTurnIndex: (e.dealerIndex + 1) % _config.playerCount,
        isDealt: true,
      ),
      PlayerPassedEvent e => _applyPass(state, e),
      PlayerPickedEvent e => _applyPick(state, e),
      CardsBuriedEvent e => _applyBury(state, e),
      CardPlayedEvent e => _applyCardPlayed(state, e),
    };
  }

  MasterGameState _applyPass(MasterGameState state, PlayerPassedEvent event) {
    final newPassed = {...state.passedIndices, event.playerId.value};
    if (newPassed.length == _config.playerCount) {
      return MasterGameState(
        hands: state.hands,
        blind: state.blind,
        dealerIndex: state.dealerIndex,
        currentPickerTurnIndex: state.currentPickerTurnIndex,
        isDealt: state.isDealt,
        passedIndices: newPassed,
        internalPhase: InternalPhase.allPass,
      );
    }
    return MasterGameState(
      hands: state.hands,
      blind: state.blind,
      dealerIndex: state.dealerIndex,
      currentPickerTurnIndex: (event.playerId.value + 1) % _config.playerCount,
      isDealt: state.isDealt,
      passedIndices: newPassed,
    );
  }

  MasterGameState _applyPick(MasterGameState state, PlayerPickedEvent event) {
    final pickerIndex = event.playerId.value;
    final newHand = List<Card>.unmodifiable([
      ...state.hands[event.playerId]!,
      ...state.blind,
    ]);
    return MasterGameState(
      hands: Map.unmodifiable({...state.hands, event.playerId: newHand}),
      blind: state.blind,
      dealerIndex: state.dealerIndex,
      currentPickerTurnIndex: pickerIndex,
      isDealt: state.isDealt,
      passedIndices: state.passedIndices,
      pickerIndex: pickerIndex,
      internalPhase: InternalPhase.bury,
    );
  }

  MasterGameState _applyBury(MasterGameState state, CardsBuriedEvent event) {
    final newHand = List<Card>.unmodifiable(
      state.hands[event.playerId]!.where((c) => !event.cards.contains(c)),
    );
    final newHands = Map<PlayerId, List<Card>>.unmodifiable({
      ...state.hands,
      event.playerId: newHand,
    });

    int? partnerIndex;
    if (!event.isGoingAlone) {
      const jD = Card(Suit.diamonds, Rank.jack);
      for (var i = 0; i < _config.playerCount; i++) {
        if (i != event.playerId.value &&
            (newHands[PlayerId(i)] ?? []).contains(jD)) {
          partnerIndex = i;
          break;
        }
      }
    }

    return MasterGameState(
      hands: newHands,
      blind: state.blind,
      dealerIndex: state.dealerIndex,
      currentPickerTurnIndex: state.currentPickerTurnIndex,
      isDealt: state.isDealt,
      passedIndices: state.passedIndices,
      pickerIndex: state.pickerIndex,
      internalPhase: InternalPhase.trickPlay,
      buriedCards: List.unmodifiable(event.cards),
      isPickerGoingAlone: event.isGoingAlone,
      partnerIndex: partnerIndex,
      currentLeaderIndex: (state.dealerIndex + 1) % _config.playerCount,
    );
  }

  MasterGameState _applyCardPlayed(
    MasterGameState state,
    CardPlayedEvent event,
  ) {
    final newHand = List<Card>.unmodifiable(
      state.hands[event.playerId]!.where((c) => c != event.card),
    );
    final newHands = Map<PlayerId, List<Card>>.unmodifiable({
      ...state.hands,
      event.playerId: newHand,
    });
    final newTrick = List<TrickPlay>.unmodifiable([
      ...state.currentTrick,
      TrickPlay(playerIndex: event.playerId.value, card: event.card),
    ]);

    if (newTrick.length < _config.playerCount) {
      return MasterGameState(
        hands: newHands,
        blind: state.blind,
        dealerIndex: state.dealerIndex,
        currentPickerTurnIndex: state.currentPickerTurnIndex,
        isDealt: state.isDealt,
        passedIndices: state.passedIndices,
        pickerIndex: state.pickerIndex,
        internalPhase: state.internalPhase,
        buriedCards: state.buriedCards,
        isPickerGoingAlone: state.isPickerGoingAlone,
        partnerIndex: state.partnerIndex,
        currentLeaderIndex: state.currentLeaderIndex,
        currentTrick: newTrick,
        completedTricks: state.completedTricks,
      );
    }

    final winnerIndex = TrickResolver.winner(newTrick);
    final trickPoints = newTrick.fold<int>(
      0,
      (s, p) => s + TrumpEvaluator.cardPoints(p.card),
    );
    final newCompleted = List<CompletedTrick>.unmodifiable([
      ...state.completedTricks,
      CompletedTrick(winnerIndex: winnerIndex, trickPoints: trickPoints),
    ]);

    final nextPhase = newCompleted.length == _config.handSize
        ? InternalPhase.handResult
        : InternalPhase.trickPlay;

    return MasterGameState(
      hands: newHands,
      blind: state.blind,
      dealerIndex: state.dealerIndex,
      currentPickerTurnIndex: state.currentPickerTurnIndex,
      isDealt: state.isDealt,
      passedIndices: state.passedIndices,
      pickerIndex: state.pickerIndex,
      internalPhase: nextPhase,
      buriedCards: state.buriedCards,
      isPickerGoingAlone: state.isPickerGoingAlone,
      partnerIndex: state.partnerIndex,
      currentLeaderIndex: winnerIndex,
      currentTrick: const [],
      completedTricks: newCompleted,
    );
  }

  void _notifyObservers() {
    for (final obs in List.of(_observers)) {
      obs.onChanged();
    }
  }

  @override
  void addObserver(GameObserver observer) => _observers.add(observer);

  @override
  void removeObserver(GameObserver observer) => _observers.remove(observer);

  @override
  PlayerView viewFor(PlayerId id) {
    final s = _state;
    final myIndex = id.value;
    final opponents = [
      for (var offset = 1; offset < _config.playerCount; offset++)
        _opponent(
          index: (myIndex + offset) % _config.playerCount,
          offset: offset,
          state: s,
        ),
    ];
    return PlayerView(
      id: id,
      hand: s.hands[id] ?? const <Card>[],
      opponents: opponents,
      isMyTurnToAct: _isMyTurnToAct(myIndex, s),
      phase: _phaseFor(id, s),
      isIDealer: myIndex == s.dealerIndex,
      isIPicker: myIndex == s.pickerIndex,
      isIGoingAlone: myIndex == s.pickerIndex && s.isPickerGoingAlone,
      isIPartner: myIndex == s.partnerIndex,
    );
  }

  bool _isMyTurnToAct(int myIndex, MasterGameState state) {
    return switch (state.internalPhase) {
      InternalPhase.pick => myIndex == state.currentPickerTurnIndex,
      InternalPhase.bury => myIndex == state.pickerIndex,
      InternalPhase.trickPlay =>
        myIndex ==
            (state.currentLeaderIndex + state.currentTrick.length) %
                _config.playerCount,
      _ => false,
    };
  }

  PhaseView _phaseFor(PlayerId id, MasterGameState state) {
    return switch (state.internalPhase) {
      InternalPhase.pick => const PickPhaseView(),
      InternalPhase.allPass => const AllPassPhaseView(),
      InternalPhase.bury => BuryPhaseView(
        isChopAllowed:
            id.value == state.pickerIndex &&
            !(state.hands[id] ?? const <Card>[]).contains(
              const Card(Suit.diamonds, Rank.jack),
            ),
      ),
      InternalPhase.trickPlay => TrickPlayPhaseView(
        leadSuit: state.currentTrick.isEmpty
            ? null
            : TrumpEvaluator.isTrump(state.currentTrick.first.card)
            ? null
            : state.currentTrick.first.card.suit,
      ),
      InternalPhase.handResult => HandResultPhaseView(
        results: _computeScores(state),
      ),
      _ => const PickPhaseView(),
    };
  }

  List<PlayerScore> _computeScores(MasterGameState state) {
    final pickerIndex = state.pickerIndex!;
    final partnerIndex = state.partnerIndex;
    final isGoingAlone = state.isPickerGoingAlone || partnerIndex == null;

    final cardPointsPerPlayer = <int, int>{
      for (var i = 0; i < _config.playerCount; i++) i: 0,
    };
    for (final trick in state.completedTricks) {
      cardPointsPerPlayer[trick.winnerIndex] =
          (cardPointsPerPlayer[trick.winnerIndex] ?? 0) + trick.trickPoints;
    }

    final buriedPoints = state.buriedCards.fold<int>(
      0,
      (s, c) => s + TrumpEvaluator.cardPoints(c),
    );
    final pickerTeamPoints =
        (cardPointsPerPlayer[pickerIndex] ?? 0) +
        (isGoingAlone ? 0 : (cardPointsPerPlayer[partnerIndex] ?? 0)) +
        buriedPoints;

    final pickerWon = pickerTeamPoints > 60;
    final sign = pickerWon ? 1 : -1;

    final gamePoints = <int, int>{};
    if (isGoingAlone) {
      gamePoints[pickerIndex] = sign * (_config.playerCount - 1);
      for (var i = 0; i < _config.playerCount; i++) {
        if (i != pickerIndex) gamePoints[i] = -sign;
      }
    } else {
      gamePoints[pickerIndex] = sign * 2;
      gamePoints[partnerIndex] = sign;
      for (var i = 0; i < _config.playerCount; i++) {
        if (i != pickerIndex && i != partnerIndex) gamePoints[i] = -sign;
      }
    }

    return [
      for (var i = 0; i < _config.playerCount; i++)
        PlayerScore(
          id: PlayerId(i),
          handPoints: gamePoints[i] ?? 0,
          runningTotal: gamePoints[i] ?? 0,
        ),
    ];
  }

  SeatedPlayer _opponent({
    required int index,
    required int offset,
    required MasterGameState state,
  }) {
    final seat = switch (offset) {
      1 => RelativeSeat.left,
      2 => RelativeSeat.across,
      _ => RelativeSeat.right,
    };
    return SeatedPlayer(
      id: PlayerId(index),
      seat: seat,
      isPassed: state.passedIndices.contains(index),
      isDealer: index == state.dealerIndex,
      isPicker: index == state.pickerIndex,
      isGoingAlone: index == state.pickerIndex && state.isPickerGoingAlone,
      isPartner: index == state.partnerIndex,
      cardPlayed: _cardPlayedThisTrick(index, state),
    );
  }

  Card? _cardPlayedThisTrick(int playerIndex, MasterGameState state) {
    for (final play in state.currentTrick) {
      if (play.playerIndex == playerIndex) return play.card;
    }
    return null;
  }

  @override
  CommandResult submit(Command command) {
    return switch (command) {
      PassCommand c => _handlePass(c),
      PickCommand c => _handlePick(c),
      BuryCommand c => _handleBury(c),
      PlayCardCommand c => _handlePlayCard(c),
      StealCommand() => const Rejected('Not yet implemented'),
      DeclineStealCommand() => const Rejected('Not yet implemented'),
    };
  }

  CommandResult _handlePass(PassCommand command) {
    if (_state.internalPhase != InternalPhase.pick) {
      return const Rejected('Not in pick phase');
    }
    if (command.playerId.value != _state.currentPickerTurnIndex) {
      return Rejected('Not your turn to pick or pass');
    }
    _state = _apply(_state, PlayerPassedEvent(command.playerId));
    _notifyObservers();
    return const Accepted();
  }

  CommandResult _handlePick(PickCommand command) {
    if (_state.internalPhase != InternalPhase.pick) {
      return const Rejected('Not in pick phase');
    }
    if (command.playerId.value != _state.currentPickerTurnIndex) {
      return Rejected('Not your turn to pick or pass');
    }
    _state = _apply(_state, PlayerPickedEvent(command.playerId));
    _notifyObservers();
    return const Accepted();
  }

  CommandResult _handleBury(BuryCommand command) {
    if (_state.internalPhase != InternalPhase.bury) {
      return const Rejected('Not in bury phase');
    }
    if (command.playerId.value != _state.pickerIndex) {
      return const Rejected('Only the picker may bury');
    }
    if (command.cards.length != _config.blindSize) {
      return Rejected('Must bury exactly ${_config.blindSize} cards');
    }
    final hand = _state.hands[command.playerId] ?? const [];
    for (final card in command.cards) {
      if (!hand.contains(card)) {
        return Rejected('Card ${card.label} is not in your hand');
      }
    }
    const jD = Card(Suit.diamonds, Rank.jack);
    final buriesJD = command.cards.contains(jD);
    if (buriesJD && !command.chop) {
      return const Rejected('Must announce when burying J♦');
    }
    final postBuryHand = hand.where((c) => !command.cards.contains(c));
    if (command.chop && postBuryHand.contains(jD)) {
      return const Rejected('Cannot chop while holding J♦');
    }
    _state = _apply(
      _state,
      CardsBuriedEvent(
        playerId: command.playerId,
        cards: command.cards,
        isGoingAlone: command.chop || buriesJD,
      ),
    );
    _notifyObservers();
    return const Accepted();
  }

  CommandResult _handlePlayCard(PlayCardCommand command) {
    if (_state.internalPhase != InternalPhase.trickPlay) {
      return const Rejected('Not in trick play phase');
    }
    final myIndex = command.playerId.value;
    final nextToPlay =
        (_state.currentLeaderIndex + _state.currentTrick.length) %
        _config.playerCount;
    if (myIndex != nextToPlay) {
      return const Rejected('Not your turn to play');
    }
    final hand = _state.hands[command.playerId] ?? const [];
    if (!hand.contains(command.card)) {
      return Rejected('Card ${command.card.label} is not in your hand');
    }
    if (!_canPlay(command.card, hand, _state.currentTrick)) {
      return const Rejected('Must follow suit');
    }
    _state = _apply(
      _state,
      CardPlayedEvent(playerId: command.playerId, card: command.card),
    );
    _notifyObservers();
    return const Accepted();
  }

  bool _canPlay(Card card, List<Card> hand, List<TrickPlay> currentTrick) {
    if (currentTrick.isEmpty) return true;
    final leadCard = currentTrick.first.card;
    final trumpLed = TrumpEvaluator.isTrump(leadCard);
    if (trumpLed) {
      final hasTrump = hand.any(TrumpEvaluator.isTrump);
      return hasTrump ? TrumpEvaluator.isTrump(card) : true;
    }
    final leadSuit = leadCard.suit;
    final hasLeadSuit = hand.any(
      (c) => !TrumpEvaluator.isTrump(c) && c.suit == leadSuit,
    );
    return hasLeadSuit
        ? !TrumpEvaluator.isTrump(card) && card.suit == leadSuit
        : true;
  }
}
