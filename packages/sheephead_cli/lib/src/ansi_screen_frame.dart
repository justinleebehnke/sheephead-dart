import 'screen_frame.interface.dart';

class AnsiScreenFrame implements IScreenFrame {
  @override
  String render({required String content, String? error}) {
    if (error == null) return content;
    return '$content\n\n$error';
  }
}
