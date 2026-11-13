sealed class CommandResultDto {
  const CommandResultDto();
}

final class Accepted extends CommandResultDto {
  const Accepted();
}

final class Rejected extends CommandResultDto {
  const Rejected(this.reason);
  final String reason;
}
