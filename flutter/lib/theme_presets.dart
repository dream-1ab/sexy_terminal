import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xterm/xterm.dart';

import 'app_log.dart';
import 'terminal_theme_codec.dart';
import 'terminal_appearance.dart';

class TerminalThemePreset {
  const TerminalThemePreset({
    required this.id,
    required this.name,
    required this.theme,
    this.author,
    this.variant,
    this.source,
    this.userDefined = false,
  });

  final String id;
  final String name;
  final TerminalTheme theme;
  final String? author;
  final String? variant;
  final String? source;
  final bool userDefined;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'variant': variant,
    'source': source,
    'theme': terminalThemeToJson(theme),
  };

  factory TerminalThemePreset.fromJson(
    Map<String, dynamic> json, {
    bool userDefined = true,
  }) => TerminalThemePreset(
    id: json['id'] as String,
    name: json['name'] as String,
    author: json['author'] as String?,
    variant: json['variant'] as String?,
    source: json['source'] as String?,
    userDefined: userDefined,
    theme: terminalThemeFromJson(
      (json['theme'] as Map?)?.cast<String, dynamic>() ?? json,
    ),
  );
}

class ThemePresetStore extends ChangeNotifier {
  ThemePresetStore._();

  static final instance = ThemePresetStore._();

  List<TerminalThemePreset> presets = const [];
  TerminalTheme globalTheme = TerminalThemes.defaultTheme;
  TerminalAppearanceProfile globalAppearance = const TerminalAppearanceProfile(
    theme: TerminalThemes.defaultTheme,
    fontFamily: 'Ubuntu Mono',
    fontSize: 15.0,
  );
  String globalThemeId = 'user:htop';
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final bundled = jsonDecode(
      await rootBundle.loadString('assets/gogh_themes.json'),
    ) as List;
    final loaded = <TerminalThemePreset>[
      TerminalThemePreset(
        id: 'user:htop',
        name: 'Htop',
        theme: terminalThemeFromJson(const {
          'cursor': 4279740555,
          'selection': 2487877376,
          'foreground': 4278255444,
          'background': 4279374612,
          'black': 4280164905,
          'red': 4294916409,
          'green': 4280614656,
          'yellow': 4294942720,
          'blue': 4278229503,
          'magenta': 4288371126,
          'cyan': 4279942300,
          'white': 4294769916,
          'brightBlack': 4286549133,
          'brightRed': 4294907392,
          'brightGreen': 4278255481,
          'brightYellow': 4294967040,
          'brightBlue': 4282232553,
          'brightMagenta': 4294911436,
          'brightCyan': 4279672965,
          'brightWhite': 4294967295,
          'searchHitBackground': 4294967083,
          'searchHitBackgroundCurrent': 4281466662,
          'searchHitForeground': 4278190080,
        }),
        source: 'Customized Htop session',
        userDefined: true,
      ),
      const TerminalThemePreset(
        id: 'xterm:default',
        name: 'xterm Default',
        theme: TerminalThemes.defaultTheme,
        source: 'xterm',
      ),
      const TerminalThemePreset(
        id: 'xterm:white-on-black',
        name: 'White on Black',
        theme: TerminalThemes.whiteOnBlack,
        source: 'xterm',
      ),
    ];
    for (var index = 0; index < bundled.length; index++) {
      final json = (bundled[index] as Map).cast<String, dynamic>();
      loaded.add(
        TerminalThemePreset(
          id: 'gogh:$index',
          name: json['name'] as String,
          author: json['author'] as String?,
          variant: json['variant'] as String?,
          source: 'Gogh (Gogh-Co/Gogh)',
          theme: terminalThemeFromGogh(json),
        ),
      );
    }
    final userFile = await _userThemesFile();
    if (await userFile.exists()) {
      try {
        final json = jsonDecode(await userFile.readAsString()) as List;
        loaded.addAll(
          json.map(
            (item) => TerminalThemePreset.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          ),
        );
      } catch (error, stackTrace) {
        appLog(
          AppLogTag.error,
          'Failed to load user terminal theme presets.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    presets = loaded;
    final initialPreset = presets
        .where((item) => item.id == globalThemeId)
        .firstOrNull;
    if (initialPreset != null) {
      globalTheme = initialPreset.theme;
      globalAppearance = globalAppearance.copyWith(theme: initialPreset.theme);
    }
    await _loadGlobalSelection();
    _initialized = true;
    appLog(
      AppLogTag.workspace,
      'Loaded ${presets.length} terminal theme presets.',
    );
  }

  Future<void> selectGlobalTheme(String presetId) async {
    final preset = presets.cast<TerminalThemePreset?>().firstWhere(
      (item) => item?.id == presetId,
      orElse: () => null,
    );
    if (preset == null) return;
    globalThemeId = preset.id;
    globalTheme = preset.theme;
    globalAppearance = globalAppearance.copyWith(theme: preset.theme);
    notifyListeners();
    final file = await _settingsFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'globalThemeId': preset.id,
        'appearance': globalAppearance.toJson(),
      }),
    );
  }

  Future<void> updateGlobalAppearance(
    TerminalAppearanceProfile appearance,
  ) async {
    globalAppearance = appearance;
    globalTheme = appearance.theme;
    notifyListeners();
    final file = await _settingsFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'globalThemeId': globalThemeId,
        'appearance': appearance.toJson(),
      }),
    );
  }

  TerminalTheme resolveTheme({
    TerminalTheme? sessionTheme,
    TerminalTheme? workspaceTheme,
  }) => sessionTheme ?? workspaceTheme ?? globalTheme;

  TerminalAppearanceProfile resolveAppearance({
    TerminalAppearanceProfile? sessionAppearance,
    TerminalAppearanceProfile? workspaceAppearance,
    TerminalTheme? sessionTheme,
    TerminalTheme? workspaceTheme,
  }) {
    final inherited = workspaceAppearance ?? globalAppearance;
    final session =
        sessionAppearance ??
        (sessionTheme == null ? null : inherited.copyWith(theme: sessionTheme));
    if (session != null) return session;
    if (workspaceAppearance != null) return workspaceAppearance;
    if (workspaceTheme != null)
      return globalAppearance.copyWith(theme: workspaceTheme);
    return globalAppearance;
  }

  Future<void> saveUserPreset(TerminalThemePreset preset) async {
    final file = await _userThemesFile();
    final userPresets = presets.where((item) => item.userDefined).toList()
      ..removeWhere((item) => item.id == preset.id)
      ..add(preset);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(userPresets.map((item) => item.toJson()).toList()),
    );
    presets = [
      ...presets.where((item) => !item.userDefined && item.id != preset.id),
      ...userPresets,
    ];
  }

  Future<File> _userThemesFile() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/themes');
    await directory.create(recursive: true);
    return File('${directory.path}/user_themes.json');
  }

  Future<File> _settingsFile() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/settings');
    await directory.create(recursive: true);
    return File('${directory.path}/settings.json');
  }

  Future<void> _loadGlobalSelection() async {
    final file = await _settingsFile();
    if (!await file.exists()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map;
      final id = json['globalThemeId'] as String?;
      if (id != null) {
        final preset = presets.cast<TerminalThemePreset?>().firstWhere(
          (item) => item?.id == id,
          orElse: () => null,
        );
        if (preset != null) {
          globalThemeId = preset.id;
          globalTheme = preset.theme;
          globalAppearance = globalAppearance.copyWith(theme: preset.theme);
        }
      }
      final appearance = (json['appearance'] as Map?)?.cast<String, dynamic>();
      if (appearance != null) {
        globalAppearance = TerminalAppearanceProfile.fromJson(appearance);
        globalTheme = globalAppearance.theme;
      }
    } catch (error, stackTrace) {
      appLog(
        AppLogTag.error,
        'Failed to load global terminal theme selection.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
