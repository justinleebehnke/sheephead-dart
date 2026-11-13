import 'package:sheephead_engine/sheephead_engine.dart';

sealed class ParseResult {
  const ParseResult();
}

final class Submit extends ParseResult {
  const Submit(this.command);
  final CommandDto command;
}

final class Advance extends ParseResult {
  const Advance();
}

final class Unrecognized extends ParseResult {
  const Unrecognized();
}

final class Quit extends ParseResult {
  const Quit();
}
