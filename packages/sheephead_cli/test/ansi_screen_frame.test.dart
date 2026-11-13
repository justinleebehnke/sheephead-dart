import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:test/test.dart';

void main() {
  late AnsiScreenFrame frame;

  setUp(() => frame = AnsiScreenFrame());

  test('renders content when there is no error', () {
    expect(frame.render(content: 'Pick or pass?'), 'Pick or pass?');
  });

  test('appends error below content when present', () {
    expect(
      frame.render(content: 'Pick or pass?', error: 'invalid play'),
      'Pick or pass?\n\ninvalid play',
    );
  });
}
