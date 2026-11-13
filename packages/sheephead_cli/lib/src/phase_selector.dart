import 'package:sheephead_engine/sheephead_engine.dart';

import 'all_pass_phase.dart';
import 'bury_phase.dart';
import 'bury_selection.dart';
import 'chop_phase.dart';
import 'game_phase.interface.dart';
import 'game_result_phase.dart';
import 'hand_result_phase.dart';
import 'pick_pass_phase.dart';
import 'steal_phase.dart';
import 'trick_play_phase.dart';
import 'trick_result_phase.dart';

IGamePhase selectPhase(PlayerViewDto view, BurySelection burySelection) {
  switch (view.phase) {
    case HandResultPhaseViewDto():
      burySelection.cards = null;
      return HandResultPhase();
    case GameResultPhaseViewDto():
      burySelection.cards = null;
      return GameResultPhase();
    case TrickResultPhaseViewDto():
      return TrickResultPhase();
    case StealPhaseViewDto():
      return StealPhase();
    case BuryPhaseViewDto():
      return burySelection.cards != null
          ? ChopPhase(burySelection, view.id)
          : BuryPhase(burySelection, view.id);
    case PickPhaseViewDto():
      return PickPassPhase(view.id);
    case AllPassPhaseViewDto():
      return AllPassPhase();
    case TrickPlayPhaseViewDto():
      return TrickPlayPhase(view.id);
  }
}
