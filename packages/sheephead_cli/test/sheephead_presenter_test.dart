import 'dart:async';

import 'package:sheephead_cli/sheephead_cli.dart';
import 'package:sheephead_engine/sheephead_engine.dart';
import 'package:test/test.dart';

void main() {
  late _FakeGameSession session;
  late _FakeScreenTemplate layout;
  late _FakeGamePhase phase;

  setUp(() {
    session = _FakeGameSession();
    layout = _FakeScreenTemplate();
    phase = _FakeGamePhase();
  });

  SheepheadPresenter makePresenter({PhaseSelector? selector}) =>
      SheepheadPresenter(
        session,
        const PlayerId(0),
        layout,
        initialPhase: phase,
        selector: selector ?? (_) => phase,
      );

  group('on construction', () {
    test('emits one display', () async {
      final emissions = <String>[];
      makePresenter().display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
    });

    test('display content comes from the phase and layout', () async {
      phase.contentResult = 'Pick or pass?';
      layout.outputFor = (content, _) => 'SCREEN[$content]';

      final emissions = <String>[];
      makePresenter().display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastContent, 'Pick or pass?');
      expect(emissions.single, 'SCREEN[Pick or pass?]');
    });

    test('display has no error', () async {
      makePresenter().display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastError, isNull);
    });
  });

  group('when input is not recognized by the phase', () {
    setUp(() => phase.interpretResult = const Unrecognized());

    test('emits one display', () async {
      final presenter = makePresenter();
      final emissions = <String>[];
      presenter.display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('garbage');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
    });

    test('display includes an error', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('garbage');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastError, isNotNull);
    });

    test('does not submit a command to the session', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});

      presenter.submitLine('garbage');

      expect(session.lastSubmitted, isNull);
    });
  });

  group('when the session rejects the command', () {
    setUp(() {
      phase.interpretResult = Submit(_FakeCommand());
      session.result = const Rejected('invalid play');
    });

    test('emits one display', () async {
      final presenter = makePresenter();
      final emissions = <String>[];
      presenter.display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('3');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
    });

    test('display includes the rejection reason as an error', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('3');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastError, 'invalid play');
    });
  });

  group('when the phase returns Advance', () {
    setUp(() => phase.interpretResult = const Advance());

    test('emits one display', () async {
      final presenter = makePresenter();
      final emissions = <String>[];
      presenter.display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
    });

    test('display has no error', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastError, isNull);
    });

    test('does not submit a command to the session', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});

      presenter.submitLine('');

      expect(session.lastSubmitted, isNull);
    });

    test('renders using the phase returned by the selector', () async {
      final nextPhase = _FakeGamePhase()..contentResult = 'Your lead.';
      final presenter = makePresenter(selector: (_) => nextPhase);
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastContent, 'Your lead.');
    });
  });

  group('when disposed', () {
    test('removes itself as an observer from the session', () {
      final presenter = makePresenter();
      expect(session.observers, contains(presenter));

      presenter.dispose();

      expect(session.observers, isNot(contains(presenter)));
    });
  });

  group('when the session notifies observers', () {
    test('emits one display', () async {
      final presenter = makePresenter();
      final emissions = <String>[];
      presenter.display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      session.notifyObservers();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
    });
  });

  group('when the session accepts the command', () {
    setUp(() {
      phase.interpretResult = Submit(_FakeCommand());
      session.result = const Accepted();
    });

    test('emits one display', () async {
      final presenter = makePresenter();
      final emissions = <String>[];
      presenter.display.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('pick');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
    });

    test('display has no error', () async {
      final presenter = makePresenter();
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('pick');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastError, isNull);
    });

    test('renders using the phase returned by the selector', () async {
      final nextPhase = _FakeGamePhase()..contentResult = 'Bury two cards.';
      final presenter = makePresenter(selector: (_) => nextPhase);
      presenter.display.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      presenter.submitLine('pick');
      await Future<void>.delayed(Duration.zero);

      expect(layout.lastContent, 'Bury two cards.');
    });
  });
}

// --- fakes ---

class _FakeCommand implements Command {}

class _FakeGameSession implements GameSession {
  PlayerView viewResult = PlayerView();
  CommandResult result = const Accepted();
  Command? lastSubmitted;
  final observers = <GameObserver>[];

  @override
  void addObserver(GameObserver observer) => observers.add(observer);

  @override
  void removeObserver(GameObserver observer) => observers.remove(observer);

  @override
  PlayerView viewFor(PlayerId id) => viewResult;

  @override
  CommandResult submit(Command command) {
    lastSubmitted = command;
    return result;
  }

  void notifyObservers() {
    for (final o in List.of(observers)) {
      o.onChanged();
    }
  }
}

class _FakeGamePhase implements GamePhase {
  ParseResult interpretResult = const Unrecognized();
  String contentResult = '';

  @override
  ParseResult interpret(String input) => interpretResult;

  @override
  String buildContent(PlayerView view) => contentResult;
}

class _FakeScreenTemplate implements ScreenTemplate {
  String? lastContent;
  String? lastError;
  String Function(String content, String? error) outputFor = (content, _) =>
      content;

  @override
  String render({required String content, String? error}) {
    lastContent = content;
    lastError = error;
    return outputFor(content, error);
  }
}
