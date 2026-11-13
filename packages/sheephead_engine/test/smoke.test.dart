import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  test('engine exposes a non-empty version', () {
    expect(engineVersion, isNotEmpty);
  });
}
