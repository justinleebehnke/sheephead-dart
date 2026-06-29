import 'terminal_presenter.dart';

const _clearScreen = '\x1B[2J\x1B[H';

class Terminal {
  Terminal(
    TerminalPresenter presenter, {
    required void Function(String) output,
    required Stream<String> input,
  }) {
    presenter.display.listen((content) => output('$_clearScreen$content'));
    input.listen(presenter.submitLine);
  }
}
