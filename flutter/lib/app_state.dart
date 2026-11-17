import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

class TerminalSession {
  TerminalSession()
      : terminal = Terminal(maxLines: 10000),
        controller = TerminalController() {
    final shell = Platform.environment['SHELL'] ??
        (Platform.isWindows ? 'cmd.exe' : 'bash');
    pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    pty.output.cast<List<int>>().transform(utf8.decoder).listen(terminal.write);
    pty.exitCode.then((code) {
      terminal.write('\r\n[process exited: $code]\r\n');
    });
    terminal.onOutput = (data) => pty.write(utf8.encode(data));
    terminal.onResize = (width, height, _, __) => pty.resize(height, width);
  }

  final Terminal terminal;
  final TerminalController controller;
  late final Pty pty;

  void dispose() {
    pty.kill();
    controller.dispose();
  }
}

class AppState {
  int nextTerminalNumber = 1;
  final sessions = <String, TerminalSession>{};

  TerminalSession createSession(String id) {
    final session = TerminalSession();
    sessions[id] = session;
    return session;
  }

  void dispose() {
    for (final session in sessions.values) {
      session.dispose();
    }
    sessions.clear();
  }
}
