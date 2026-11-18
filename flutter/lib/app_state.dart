import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'profile_models.dart';
import 'profile_store.dart';

class TerminalSession {
  TerminalSession({SessionProfile? profile})
      : terminal = Terminal(maxLines: 10000),
        controller = TerminalController() {
    final shell = profile?.shell ?? Platform.environment['SHELL'] ??
        (Platform.isWindows ? 'cmd.exe' : 'bash');
    pty = Pty.start(
      shell,
      workingDirectory: profile?.workingDirectory,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    pty.output.cast<List<int>>().transform(utf8.decoder).listen(terminal.write);
    pty.exitCode.then((code) {
      terminal.write('\r\n[process exited: $code]\r\n');
    });
    terminal.onOutput = (data) => pty.write(utf8.encode(data));
    terminal.onResize = (width, height, _, __) => pty.resize(height, width);
    if (profile != null && profile.startupCommands.isNotEmpty) {
      Future<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        for (final command in profile.startupCommands) {
          pty.write(utf8.encode('$command\n'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      });
    }
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
  final profileStore = ProfileStore();
  List<WorkspaceProfile> profiles = [];
  WorkspaceProfile? activeProfile;
  int nextTerminalNumber = 1;
  final sessions = <String, TerminalSession>{};

  TerminalSession createSession(String id, {SessionProfile? definition}) {
    final session = TerminalSession(profile: definition);
    sessions[id] = session;
    return session;
  }

  Future<void> loadProfiles() async {
    profiles = await profileStore.loadProfiles();
  }

  Future<WorkspaceProfile> createDefaultProfile() async {
    final profile = WorkspaceProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Default workspace',
      sessions: [
        SessionProfile(id: 'terminal-1', name: 'Terminal 1'),
      ],
    );
    await profileStore.saveProfile(profile);
    profiles = [...profiles, profile];
    return profile;
  }

  void dispose() {
    for (final session in sessions.values) {
      session.dispose();
    }
    sessions.clear();
  }
}
