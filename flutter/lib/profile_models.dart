import 'dart:ui';

import 'package:xterm/xterm.dart';

import 'terminal_theme_codec.dart';
import 'terminal_appearance.dart';

class SessionProfile {
  SessionProfile({
    required this.id,
    required this.name,
    this.color = const Color(0xff00b0ff),
    this.icon = 'terminal',
    this.terminalTheme,
    this.appearance,
    this.shell,
    this.workingDirectory,
    this.startupCommands = const [],
  });

  final String id;
  String name;
  Color color;
  String icon;
  TerminalTheme? terminalTheme;
  TerminalAppearanceProfile? appearance;
  String? shell;
  String? workingDirectory;
  List<String> startupCommands;

  SessionProfile copyWith({
    String? name,
    Color? color,
    String? icon,
    TerminalTheme? terminalTheme,
    TerminalAppearanceProfile? appearance,
    String? shell,
    String? workingDirectory,
    List<String>? startupCommands,
    bool clearShell = false,
    bool clearWorkingDirectory = false,
  }) => SessionProfile(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    terminalTheme: terminalTheme ?? this.terminalTheme,
    appearance: appearance ?? this.appearance,
    shell: clearShell ? null : (shell ?? this.shell),
    workingDirectory: clearWorkingDirectory
        ? null
        : (workingDirectory ?? this.workingDirectory),
    startupCommands: startupCommands ?? this.startupCommands,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'icon': icon,
    if (terminalTheme != null)
      'terminalTheme': terminalThemeToJson(terminalTheme!),
    if (appearance != null) 'appearance': appearance!.toJson(),
    'shell': shell,
    'workingDirectory': workingDirectory,
    'startupCommands': startupCommands,
  };

  factory SessionProfile.fromJson(Map<String, dynamic> json) {
    return SessionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color((json['color'] as num?)?.toInt() ?? 0xff00b0ff),
      icon: json['icon'] as String? ?? 'terminal',
      terminalTheme: (json['terminalTheme'] as Map?) == null
          ? null
          : terminalThemeFromJson(
              (json['terminalTheme'] as Map).cast<String, dynamic>(),
            ),
      appearance: (json['appearance'] as Map?) == null
          ? null
          : TerminalAppearanceProfile.fromJson(
              (json['appearance'] as Map).cast<String, dynamic>(),
            ),
      shell: json['shell'] as String?,
      workingDirectory: json['workingDirectory'] as String?,
      startupCommands: [
        for (final command in (json['startupCommands'] as List? ?? const []))
          command as String,
      ],
    );
  }
}

class WorkspaceProfile {
  WorkspaceProfile({
    required this.id,
    required this.name,
    this.sessions = const [],
    this.terminalTheme,
    this.appearance,
    this.dockLayout,
  });

  final String id;
  String name;
  List<SessionProfile> sessions;
  TerminalTheme? terminalTheme;
  TerminalAppearanceProfile? appearance;
  Map<String, dynamic>? dockLayout;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sessions': sessions.map((session) => session.toJson()).toList(),
    if (terminalTheme != null)
      'terminalTheme': terminalThemeToJson(terminalTheme!),
    if (appearance != null) 'appearance': appearance!.toJson(),
    'dockLayout': dockLayout,
  };

  factory WorkspaceProfile.fromJson(Map<String, dynamic> json) {
    return WorkspaceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      sessions: [
        for (final session in (json['sessions'] as List? ?? const []))
          SessionProfile.fromJson(session as Map<String, dynamic>),
      ],
      terminalTheme: (json['terminalTheme'] as Map?) == null
          ? null
          : terminalThemeFromJson(
              (json['terminalTheme'] as Map).cast<String, dynamic>(),
            ),
      appearance: (json['appearance'] as Map?) == null
          ? null
          : TerminalAppearanceProfile.fromJson(
              (json['appearance'] as Map).cast<String, dynamic>(),
            ),
      dockLayout: (json['dockLayout'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
