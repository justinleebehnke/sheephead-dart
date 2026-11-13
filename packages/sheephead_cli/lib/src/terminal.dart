import 'terminal_presenter.interface.dart';

const _clearScreen = '\x1B[2J\x1B[H';

class Terminal {
  Terminal(
    ITerminalPresenter presenter, {
    required void Function(String) output,
    required Stream<String> input,
  }) {
    final inputSubscription = input.listen(presenter.submitLine);
    presenter.display.listen(
      (content) => output('$_clearScreen$content'),
      onDone: inputSubscription.cancel,
    );
  }
}
