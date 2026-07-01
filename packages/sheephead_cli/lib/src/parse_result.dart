import 'package:sheephead_engine/sheephead_engine.dart';

sealed class ParseResult {
  const ParseResult();
}

final class Submit extends ParseResult {
  const Submit(this.command);
  final Command command;
}

final class Advance extends ParseResult {
  const Advance();
}

final class Unrecognized extends ParseResult {
  const Unrecognized();
}
