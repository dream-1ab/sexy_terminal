import 'package:xterm/xterm.dart';

import 'terminal_theme_codec.dart';

class TerminalAppearanceProfile {
  const TerminalAppearanceProfile({
    required this.theme,
    this.fontFamily = 'Ubuntu Mono',
    this.fontFamilyFallback = const [],
    this.fontSize = 15.0,
    this.lineHeight = 1.2,
  });

  final TerminalTheme theme;
  final String fontFamily;
  final List<String> fontFamilyFallback;
  final double fontSize;
  final double lineHeight;

  TerminalAppearanceProfile copyWith({
    TerminalTheme? theme,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? lineHeight,
  }) => TerminalAppearanceProfile(
    theme: theme ?? this.theme,
    fontFamily: fontFamily ?? this.fontFamily,
    fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
  );

  TerminalStyle get textStyle => TerminalStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    height: lineHeight,
  );

  Map<String, dynamic> toJson() => {
    'theme': terminalThemeToJson(theme),
    'fontFamily': fontFamily,
    'fontFamilyFallback': fontFamilyFallback,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
  };

  factory TerminalAppearanceProfile.fromJson(Map<String, dynamic> json) {
    return TerminalAppearanceProfile(
      theme: terminalThemeFromJson(
        (json['theme'] as Map?)?.cast<String, dynamic>() ?? json,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'Ubuntu Mono',
      fontFamilyFallback: [
        for (final item in (json['fontFamilyFallback'] as List? ?? const []))
          item as String,
      ],
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 15.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
    );
  }
}
