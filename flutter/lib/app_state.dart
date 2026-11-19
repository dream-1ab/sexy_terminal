import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'app_log.dart';
import 'profile_models.dart';
import 'profile_store.dart';
import 'theme_presets.dart';
import 'terminal_appearance.dart';

class TerminalSession {
  TerminalSession({
    SessionProfile? profile,
    TerminalTheme? resolvedTheme,
    bool followsGlobalTheme = true,
    TerminalAppearanceProfile? resolvedAppearance,
  }) : terminal = Terminal(maxLines: 10000),
       controller = TerminalController(),
       theme = ValueNotifier(
         (resolvedAppearance?.theme ??
             resolvedTheme ??
             profile?.terminalTheme ??
             ThemePresetStore.instance.globalTheme),
       ),
       appearance = ValueNotifier(
         resolvedAppearance ??
             TerminalAppearanceProfile(
               theme:
                   resolvedTheme ??
                   profile?.terminalTheme ??
                   ThemePresetStore.instance.globalTheme,
             ),
       ) {
    if (followsGlobalTheme) {
      ThemePresetStore.instance.addListener(_updateFromGlobalTheme);
    }
    final shell =
        profile?.shell ??
        Platform.environment['SHELL'] ??
        (Platform.isWindows ? 'cmd.exe' : 'bash');
    try {
      pty = Pty.start(
        shell,
        workingDirectory: profile?.workingDirectory,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
      );
      appLog(
        AppLogTag.terminal,
        'Started terminal session ${profile?.id ?? '(unnamed)'} '
        'with ${profile?.startupCommands.length ?? 0} startup command(s).',
      );
    } catch (error, stackTrace) {
      appLog(
        AppLogTag.error,
        'Failed to start terminal session ${profile?.id ?? '(unnamed)'}.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _outputSubscription = pty.output
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(
          (data) {
            if (!_disposed) terminal.write(data);
          },
          onError: (Object error, StackTrace stackTrace) {
            appLog(
              AppLogTag.error,
              'Terminal output stream failed for ${profile?.id ?? '(unnamed)'}.',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
    unawaited(
      pty.exitCode.then(
        (code) {
          appLog(
            AppLogTag.terminal,
            'Terminal session ${profile?.id ?? '(unnamed)'} exited with code $code.',
          );
          if (!_disposed) terminal.write('\r\n[process exited: $code]\r\n');
        },
        onError: (Object error, StackTrace stackTrace) {
          appLog(
            AppLogTag.error,
            'Could not read exit status for ${profile?.id ?? '(unnamed)'}.',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
    terminal.onOutput = (data) => pty.write(utf8.encode(data));
    terminal.onResize = (width, height, _, __) => pty.resize(height, width);
    if (profile != null && profile.startupCommands.isNotEmpty) {
      unawaited(_runStartupCommands(profile.id, profile.startupCommands));
    }
  }

  final Terminal terminal;
  final TerminalController controller;
  final ValueNotifier<TerminalTheme> theme;
  final ValueNotifier<TerminalAppearanceProfile> appearance;
  late final Pty pty;
  late final StreamSubscription<String> _outputSubscription;
  var _disposed = false;

  void updateTheme(TerminalTheme value) {
    theme.value = value;
    appearance.value = appearance.value.copyWith(theme: value);
  }

  void updateAppearance(TerminalAppearanceProfile value) {
    appearance.value = value;
    theme.value = value.theme;
  }

  void _updateFromGlobalTheme() {
    if (!_disposed)
      updateAppearance(ThemePresetStore.instance.globalAppearance);
  }

  Future<void> _runStartupCommands(
    String sessionId,
    List<String> commands,
  ) async {
    try {
      appLog(
        AppLogTag.terminal,
        'Running ${commands.length} startup command(s) for $sessionId.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (final command in commands) {
        if (_disposed) {
          appLog(
            AppLogTag.terminal,
            'Stopped startup commands for disposed session $sessionId.',
          );
          return;
        }
        pty.write(utf8.encode('$command\n'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      appLog(AppLogTag.terminal, 'Finished startup commands for $sessionId.');
    } catch (error, stackTrace) {
      appLog(
        AppLogTag.error,
        'Startup commands failed for terminal session $sessionId.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    appLog(AppLogTag.terminal, 'Disposing terminal session.');
    terminal.onOutput = null;
    terminal.onResize = null;
    unawaited(_outputSubscription.cancel());
    pty.kill();
    controller.dispose();
    ThemePresetStore.instance.removeListener(_updateFromGlobalTheme);
    theme.dispose();
    appearance.dispose();
  }
}

class AppState {
  final profileStore = ProfileStore();
  List<WorkspaceProfile> profiles = [];
  WorkspaceProfile? activeProfile;
  int nextTerminalNumber = 1;
  final sessions = <String, TerminalSession>{};

  TerminalSession createSession(
    String id, {
    SessionProfile? definition,
    TerminalTheme? resolvedTheme,
    bool followsGlobalTheme = true,
    TerminalAppearanceProfile? resolvedAppearance,
  }) {
    appLog(AppLogTag.terminal, 'Creating terminal session $id.');
    final session = TerminalSession(
      profile: definition,
      resolvedTheme: resolvedTheme,
      followsGlobalTheme: followsGlobalTheme,
      resolvedAppearance: resolvedAppearance,
    );
    sessions[id] = session;
    return session;
  }

  Future<void> loadProfiles() async {
    profiles = await profileStore.loadProfiles();
    appLog(AppLogTag.workspace, 'Loaded workspace profile list.');
  }

  Future<WorkspaceProfile> createDefaultProfile() async {
    final profile = WorkspaceProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Default workspace',
      sessions: [SessionProfile(id: 'terminal-1', name: 'Terminal 1')],
    );
    await profileStore.saveProfile(profile);
    profiles = [...profiles, profile];
    appLog(
      AppLogTag.workspace,
      'Created default workspace profile (${profile.id}).',
    );
    return profile;
  }

  Future<WorkspaceProfile> duplicateProfile(WorkspaceProfile source) async {
    final profileId = DateTime.now().microsecondsSinceEpoch.toString();
    final profile = WorkspaceProfile(
      id: profileId,
      name: '${source.name} copy',
      sessions: List.generate(source.sessions.length, (index) {
        final session = source.sessions[index];
        return SessionProfile(
          id: '$profileId-session-${index + 1}',
          name: session.name,
          color: session.color,
          icon: session.icon,
          terminalTheme: session.terminalTheme,
          appearance: session.appearance,
          shell: session.shell,
          workingDirectory: session.workingDirectory,
          startupCommands: List.of(session.startupCommands),
        );
      }),
      terminalTheme: source.terminalTheme,
      appearance: source.appearance,
    );
    await profileStore.saveProfile(profile);
    profiles = [...profiles, profile];
    appLog(
      AppLogTag.workspace,
      'Duplicated workspace profile ${source.id} as ${profile.id}.',
    );
    return profile;
  }

  void dispose() {
    appLog(
      AppLogTag.workspace,
      'Disposing app state with ${sessions.length} terminal session(s).',
    );
    for (final session in sessions.values) {
      session.dispose();
    }
    sessions.clear();
  }
}
