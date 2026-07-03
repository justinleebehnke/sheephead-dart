import 'package:sheephead_engine/sheephead_engine.dart';

import 'all_pass_phase.dart';
import 'bury_phase.dart';
import 'bury_selection.dart';
import 'chop_phase.dart';
import 'game_phase.dart';
import 'game_result_phase.dart';
import 'hand_result_phase.dart';
import 'pick_pass_phase.dart';
import 'steal_phase.dart';
import 'trick_play_phase.dart';
import 'trick_result_phase.dart';

GamePhase selectPhase(PlayerView view, BurySelection burySelection) {
  switch (view.phase) {
    case HandResultPhaseView():
      burySelection.cards = null;
      return HandResultPhase();
    case GameResultPhaseView():
      burySelection.cards = null;
      return GameResultPhase();
    case TrickResultPhaseView():
      return TrickResultPhase();
    case StealPhaseView():
      return StealPhase();
    case BuryPhaseView():
      return burySelection.cards != null
          ? ChopPhase(burySelection)
          : BuryPhase(burySelection);
    case PickPhaseView():
      return PickPassPhase();
    case AllPassPhaseView():
      return AllPassPhase();
    case TrickPlayPhaseView():
      return TrickPlayPhase();
  }
}
