import 'screen_frame.dart';

class AnsiScreenFrame implements ScreenFrame {
  @override
  String render({required String content, String? error}) {
    if (error == null) return content;
    return '$content\n\n$error';
  }
}
