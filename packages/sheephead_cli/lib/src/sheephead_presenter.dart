import 'dart:async';

import 'package:sheephead_engine/sheephead_engine.dart';

import 'game_observer.dart';
import 'game_phase.dart';
import 'game_session.dart';
import 'parse_result.dart';
import 'screen_template.dart';
import 'terminal_presenter.dart';

typedef PhaseSelector = GamePhase Function(PlayerView view);

class SheepheadPresenter implements TerminalPresenter, GameObserver {
  SheepheadPresenter(
    this._session,
    this._playerId,
    this._layout, {
    required GamePhase initialPhase,
    required PhaseSelector selector,
  }) : _phase = initialPhase,
       _selector = selector {
    _session.addObserver(this);
    _emit();
  }

  final GameSession _session;
  final PlayerId _playerId;
  final ScreenTemplate _layout;
  final PhaseSelector _selector;
  GamePhase _phase;
  final _controller = StreamController<String>();

  @override
  Stream<String> get display => _controller.stream;

  @override
  void onChanged() => _emit();

  @override
  void dispose() {
    _session.removeObserver(this);
    _controller.close();
  }

  @override
  void submitLine(String line) {
    switch (_phase.interpret(line)) {
      case Unrecognized():
        _emit(error: 'Unrecognized input: "$line"');
      case Advance():
        _phase = _selector(_session.viewFor(_playerId));
        _emit();
      case Submit(:final command):
        final result = _session.submit(command);
        switch (result) {
          case Rejected(:final reason):
            _emit(error: reason);
          case Accepted():
            _phase = _selector(_session.viewFor(_playerId));
            _emit();
        }
    }
  }

  void _emit({String? error}) {
    _controller.add(
      _layout.render(
        content: _phase.buildContent(_session.viewFor(_playerId)),
        error: error,
      ),
    );
  }
}
