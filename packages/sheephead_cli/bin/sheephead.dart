import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sheephead_cli/sheephead_cli.dart';

void main() {
  Terminal(
    _EchoPresenter(),
    output: stdout.write,
    input: stdin.transform(utf8.decoder).transform(const LineSplitter()),
  );
}

/// Temporary stand-in for a real [TerminalPresenter], wired up only so
/// [Terminal] can be exercised by hand against a real terminal before any
/// game logic exists. Echoes back whatever line you type. Delete once a real
/// presenter lands.
class _EchoPresenter implements TerminalPresenter {
  final _contentController = StreamController<String>();

  _EchoPresenter() {
    _contentController.add('Type something and press Enter:\n');
  }

  @override
  Stream<String> get display => _contentController.stream;

  @override
  void submitLine(String line) {
    _contentController.add(
      'You typed: "$line"\n\nType something and press Enter:\n',
    );
  }
}
