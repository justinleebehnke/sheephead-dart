import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';

void main() {
  const me = PlayerId(0);
  final burySelection = BurySelection();

  final session = SheepheadGameSession(
    GameConfig.spitzer4(),
    Shuffler(Random()),
  );

  final ais = [
    for (var i = 1; i < 4; i++) RandomAi(PlayerId(i), session, Random()),
  ];
  for (final ai in ais) {
    session.addObserver(ai);
  }

  Terminal(
    SheepheadPresenter(
      session,
      me,
      AnsiScreenFrame(),
      initialPhase: PickPassPhase(me),
      selector: (view) => selectPhase(view, burySelection),
    ),
    output: stdout.write,
    input: stdin.transform(utf8.decoder).transform(const LineSplitter()),
  );

  // Presenter is now observing — kick AIs so they act on the initial deal.
  // The cascade runs synchronously and settles on Player 0's turn before
  // any input is read.
  for (final ai in ais) {
    ai.onChanged();
  }
}
