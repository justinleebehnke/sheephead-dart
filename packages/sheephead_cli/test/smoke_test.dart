import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:test/test.dart';

void main() {
  test('cli greeting mentions it is ready', () {
    expect(greeting(), contains('ready'));
  });
}
