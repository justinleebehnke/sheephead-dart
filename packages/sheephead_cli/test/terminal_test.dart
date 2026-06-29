import 'dart:async';

import 'package:sheephead_cli/src/terminal_presenter.dart';
import 'package:sheephead_cli/src/terminal.dart';
import 'package:test/test.dart';

class FakePresenter implements TerminalPresenter {
  final _contentController = StreamController<String>();
  final List<String> linesReceived = [];

  @override
  Stream<String> get display => _contentController.stream;

  @override
  void submitLine(String line) => linesReceived.add(line);

  void emitContent(String content) => _contentController.add(content);
}

void main() {
  test(
    'clears and reprints the output whenever the presenter publishes new content',
    () async {
      final presenter = FakePresenter();
      final outputs = <String>[];
      final input = StreamController<String>();
      Terminal(presenter, output: outputs.add, input: input.stream);

      presenter.emitContent('Your hand:\n1. Seven of Diamonds');
      await Future<void>.delayed(Duration.zero);

      expect(outputs, [
        '\x1B[2J\x1B[H'
            'Your hand:\n1. Seven of Diamonds',
      ]);
    },
  );

  test('forwards each completed input line to the presenter', () async {
    final presenter = FakePresenter();
    final input = StreamController<String>();
    Terminal(presenter, output: (_) {}, input: input.stream);

    input.add('3');
    await Future<void>.delayed(Duration.zero);

    expect(presenter.linesReceived, ['3']);
  });
}
