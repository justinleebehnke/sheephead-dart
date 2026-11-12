import 'dart:math';

class Shuffler {
  const Shuffler(this._random);

  final Random _random;

  List<T> shuffle<T>(List<T> items) {
    final result = List<T>.from(items);
    for (var i = result.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }
}
