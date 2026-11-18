import 'dart:ui';

class SessionProfile {
  SessionProfile({
    required this.id,
    required this.name,
    this.color = const Color(0xff00b0ff),
    this.shell,
    this.workingDirectory,
    this.startupCommands = const [],
  });

  final String id;
  String name;
  Color color;
  String? shell;
  String? workingDirectory;
  List<String> startupCommands;

  SessionProfile copyWith({
    String? name,
    Color? color,
    String? shell,
    String? workingDirectory,
    List<String>? startupCommands,
    bool clearShell = false,
    bool clearWorkingDirectory = false,
  }) => SessionProfile(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
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
    'shell': shell,
    'workingDirectory': workingDirectory,
    'startupCommands': startupCommands,
  };

  factory SessionProfile.fromJson(Map<String, dynamic> json) {
    return SessionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color((json['color'] as num?)?.toInt() ?? 0xff00b0ff),
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
    this.dockLayout,
  });

  final String id;
  String name;
  List<SessionProfile> sessions;
  Map<String, dynamic>? dockLayout;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sessions': sessions.map((session) => session.toJson()).toList(),
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
      dockLayout: (json['dockLayout'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
