sealed class CommandResult {
  const CommandResult();
}

final class Accepted extends CommandResult {
  const Accepted();
}

final class Rejected extends CommandResult {
  const Rejected(this.reason);
  final String reason;
}
