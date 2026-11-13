abstract interface class ITerminalPresenter {
  Stream<String> get display;

  void submitLine(String line);

  void dispose();
}
