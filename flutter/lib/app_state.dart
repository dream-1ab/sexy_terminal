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
    required ThemePresetStore themeStore,
    Map<String, String>? environment,
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
             themeStore.globalTheme),
       ),
       appearance = ValueNotifier(
         resolvedAppearance ??
             TerminalAppearanceProfile(
               theme:
                   resolvedTheme ??
                   profile?.terminalTheme ??
                   themeStore.globalTheme,
             ),
       ),
       _themeStore = themeStore {
    if (followsGlobalTheme) {
      _themeStore.addListener(_updateFromGlobalTheme);
    }
    final shell =
        profile?.shell ??
        Platform.environment['SHELL'] ??
        (Platform.isWindows ? 'cmd.exe' : 'bash');
    try {
      pty = Pty.start(
        shell,
        environment: environment,
        workingDirectory: profile?.workingDirectory ?? environment?['HOME'],
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
  final ThemePresetStore _themeStore;
  late final Pty pty;
  late final StreamSubscription<String> _outputSubscription;
  var _disposed = false;
  var _terminated = false;

  void updateTheme(TerminalTheme value) {
    theme.value = value;
    appearance.value = appearance.value.copyWith(theme: value);
  }

  void updateAppearance(TerminalAppearanceProfile value) {
    appearance.value = value;
    theme.value = value.theme;
  }

  void _updateFromGlobalTheme() {
    if (!_disposed) updateAppearance(_themeStore.globalAppearance);
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

  void terminate() {
    if (_terminated) return;
    _terminated = true;
    final processId = pty.pid;
    final terminated = Platform.isWindows
        ? pty.kill()
        : Process.killPid(-processId, ProcessSignal.sigterm);
    if (!terminated) {
      pty.kill();
    }
    appLog(
      AppLogTag.terminal,
      'Terminated terminal process ${Platform.isWindows ? processId : '-$processId'} '
      '(${terminated ? 'SIGTERM sent' : 'falling back to session leader'}).',
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    appLog(AppLogTag.terminal, 'Disposing terminal session.');
    terminate();
    terminal.onOutput = null;
    terminal.onResize = null;
    unawaited(_outputSubscription.cancel());
    controller.dispose();
    _themeStore.removeListener(_updateFromGlobalTheme);
    theme.dispose();
    appearance.dispose();
  }
}

class AppState extends ChangeNotifier {
  AppState({ProfileStore? profileStore, ThemePresetStore? themeStore})
    : _profileStore = profileStore ?? ProfileStore(),
      _themeStore = themeStore ?? ThemePresetStore.instance;

  final ProfileStore _profileStore;
  final ThemePresetStore _themeStore;
  Map<String, String> _ptyEnvironment = {};
  List<WorkspaceProfile> profiles = [];
  final activatedWorkspaceIds = <String>[];

  List<TerminalThemePreset> get themePresets => _themeStore.presets;
  TerminalTheme get globalTheme => _themeStore.globalTheme;
  TerminalAppearanceProfile get globalAppearance =>
      _themeStore.globalAppearance;
  String get globalThemeId => _themeStore.globalThemeId;

  Future<void> initialize() async {
    await _themeStore.initialize();
    _ptyEnvironment = await _resolvePtyEnvironment();
    await loadProfiles();
  }

  Map<String, String> get ptyEnvironment => _ptyEnvironment;

  Future<Map<String, String>> _resolvePtyEnvironment() async {
    final environment = <String, String>{...Platform.environment};
    final shell = environment['SHELL'];
    if (Platform.isMacOS && shell != null && shell.isNotEmpty) {
      try {
        final result = await Process.run(shell, [
          '-l',
          '-c',
          'printf %s "\$PATH"',
        ]);
        final path = result.stdout.toString().trim();
        if (result.exitCode == 0 && path.isNotEmpty) {
          environment['PATH'] = path;
          appLog(
            AppLogTag.workspace,
            'Resolved login-shell PATH for terminal sessions.',
          );
        }
      } catch (error, stackTrace) {
        appLog(
          AppLogTag.error,
          'Could not resolve login-shell environment; using process environment.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return environment;
  }

  Future<void> selectGlobalTheme(String presetId) async {
    await _themeStore.selectGlobalTheme(presetId);
    notifyListeners();
  }

  Future<void> updateGlobalAppearance(
    TerminalAppearanceProfile appearance,
  ) async {
    await _themeStore.updateGlobalAppearance(appearance);
    notifyListeners();
  }

  TerminalTheme resolveTheme({
    TerminalTheme? sessionTheme,
    TerminalTheme? workspaceTheme,
  }) => _themeStore.resolveTheme(
    sessionTheme: sessionTheme,
    workspaceTheme: workspaceTheme,
  );

  TerminalAppearanceProfile resolveAppearance({
    TerminalAppearanceProfile? sessionAppearance,
    TerminalAppearanceProfile? workspaceAppearance,
    TerminalTheme? sessionTheme,
    TerminalTheme? workspaceTheme,
  }) => _themeStore.resolveAppearance(
    sessionAppearance: sessionAppearance,
    workspaceAppearance: workspaceAppearance,
    sessionTheme: sessionTheme,
    workspaceTheme: workspaceTheme,
  );

  Future<void> saveProfile(WorkspaceProfile profile) =>
      _profileStore.saveProfile(profile);

  Future<void> flushProfile(WorkspaceProfile profile) =>
      _profileStore.flushProfile(profile);

  Future<void> deleteProfile(String id) => _profileStore.deleteProfile(id);

  WorkspaceProfile? workspaceById(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  void activateWorkspace(String id) {
    if (activatedWorkspaceIds.contains(id)) return;
    activatedWorkspaceIds.add(id);
    notifyListeners();
  }

  void deactivateWorkspace(String id) {
    if (!activatedWorkspaceIds.remove(id)) return;
    notifyListeners();
  }

  void removeProfile(WorkspaceProfile profile) {
    profiles = [...profiles]..remove(profile);
    notifyListeners();
  }

  void saveProfileInMemory(WorkspaceProfile profile) {
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) return;
    profiles = [...profiles]..[index] = profile;
    notifyListeners();
  }

  Future<void> loadProfiles() async {
    profiles = await _profileStore.loadProfiles();
    notifyListeners();
    appLog(AppLogTag.workspace, 'Loaded workspace profile list.');
  }

  Future<WorkspaceProfile> createDefaultProfile() async {
    final profile = WorkspaceProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Default workspace',
      sessions: [
        SessionProfile(
          id: 'terminal-1',
          name: 'Terminal 1',
          shell: SessionProfile.defaultShell,
        ),
      ],
    );
    await saveProfile(profile);
    profiles = [...profiles, profile];
    notifyListeners();
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
    await saveProfile(profile);
    profiles = [...profiles, profile];
    notifyListeners();
    appLog(
      AppLogTag.workspace,
      'Duplicated workspace profile ${source.id} as ${profile.id}.',
    );
    return profile;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class WorkspaceRuntimeState extends ChangeNotifier {
  WorkspaceRuntimeState({required this.appState, required this.workspaceId});

  final AppState appState;
  final String workspaceId;
  final sessions = <String, TerminalSession>{};

  WorkspaceProfile get profile {
    final value = appState.workspaceById(workspaceId);
    if (value == null) {
      throw StateError('Workspace profile $workspaceId no longer exists.');
    }
    return value;
  }

  TerminalSession createSession(
    String id, {
    SessionProfile? definition,
    TerminalTheme? resolvedTheme,
    bool followsGlobalTheme = true,
    TerminalAppearanceProfile? resolvedAppearance,
  }) {
    appLog(
      AppLogTag.terminal,
      'Creating terminal session $id in workspace $workspaceId.',
    );
    sessions.remove(id)?.dispose();
    final session = TerminalSession(
      themeStore: appState._themeStore,
      environment: appState.ptyEnvironment,
      profile: definition,
      resolvedTheme: resolvedTheme,
      followsGlobalTheme: followsGlobalTheme,
      resolvedAppearance: resolvedAppearance,
    );
    sessions[id] = session;
    return session;
  }

  TerminalSession? detachSession(String id) => sessions.remove(id);

  void disposeSession(String id) => detachSession(id)?.dispose();

  @override
  void dispose() {
    appLog(
      AppLogTag.workspace,
      'Disposing workspace runtime $workspaceId with ${sessions.length} terminal session(s).',
    );
    for (final session in sessions.values) {
      session.dispose();
    }
    sessions.clear();
    super.dispose();
  }
}
