class PlayerId {
  const PlayerId(this.value);
  final int value;

  @override
  bool operator ==(Object other) => other is PlayerId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
