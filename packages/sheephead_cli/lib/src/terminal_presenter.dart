abstract class TerminalPresenter {
  Stream<String> get display;

  void submitLine(String line);

  void dispose();
}
