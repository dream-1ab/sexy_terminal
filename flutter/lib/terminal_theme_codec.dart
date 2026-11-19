import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

Map<String, dynamic> terminalThemeToJson(TerminalTheme theme) => {
  'cursor': theme.cursor.toARGB32(),
  'selection': theme.selection.toARGB32(),
  'foreground': theme.foreground.toARGB32(),
  'background': theme.background.toARGB32(),
  'black': theme.black.toARGB32(),
  'red': theme.red.toARGB32(),
  'green': theme.green.toARGB32(),
  'yellow': theme.yellow.toARGB32(),
  'blue': theme.blue.toARGB32(),
  'magenta': theme.magenta.toARGB32(),
  'cyan': theme.cyan.toARGB32(),
  'white': theme.white.toARGB32(),
  'brightBlack': theme.brightBlack.toARGB32(),
  'brightRed': theme.brightRed.toARGB32(),
  'brightGreen': theme.brightGreen.toARGB32(),
  'brightYellow': theme.brightYellow.toARGB32(),
  'brightBlue': theme.brightBlue.toARGB32(),
  'brightMagenta': theme.brightMagenta.toARGB32(),
  'brightCyan': theme.brightCyan.toARGB32(),
  'brightWhite': theme.brightWhite.toARGB32(),
  'searchHitBackground': theme.searchHitBackground.toARGB32(),
  'searchHitBackgroundCurrent': theme.searchHitBackgroundCurrent.toARGB32(),
  'searchHitForeground': theme.searchHitForeground.toARGB32(),
};

TerminalTheme terminalThemeFromJson(
  Map<String, dynamic> json, {
  TerminalTheme fallback = TerminalThemes.defaultTheme,
}) {
  Color readColor(String key, Color defaultColor) {
    final value = json[key];
    if (value is num) return Color(value.toInt());
    if (value is String) {
      final hex = value.replaceFirst('#', '');
      final normalized = hex.length == 6 ? 'ff$hex' : hex;
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return defaultColor;
  }

  return TerminalTheme(
    cursor: readColor('cursor', fallback.cursor),
    selection: readColor('selection', fallback.selection),
    foreground: readColor('foreground', fallback.foreground),
    background: readColor('background', fallback.background),
    black: readColor('black', fallback.black),
    red: readColor('red', fallback.red),
    green: readColor('green', fallback.green),
    yellow: readColor('yellow', fallback.yellow),
    blue: readColor('blue', fallback.blue),
    magenta: readColor('magenta', fallback.magenta),
    cyan: readColor('cyan', fallback.cyan),
    white: readColor('white', fallback.white),
    brightBlack: readColor('brightBlack', fallback.brightBlack),
    brightRed: readColor('brightRed', fallback.brightRed),
    brightGreen: readColor('brightGreen', fallback.brightGreen),
    brightYellow: readColor('brightYellow', fallback.brightYellow),
    brightBlue: readColor('brightBlue', fallback.brightBlue),
    brightMagenta: readColor('brightMagenta', fallback.brightMagenta),
    brightCyan: readColor('brightCyan', fallback.brightCyan),
    brightWhite: readColor('brightWhite', fallback.brightWhite),
    searchHitBackground: readColor(
      'searchHitBackground',
      fallback.searchHitBackground,
    ),
    searchHitBackgroundCurrent: readColor(
      'searchHitBackgroundCurrent',
      fallback.searchHitBackgroundCurrent,
    ),
    searchHitForeground: readColor(
      'searchHitForeground',
      fallback.searchHitForeground,
    ),
  );
}

TerminalTheme terminalThemeFromGogh(Map<String, dynamic> json) {
  final xterm = <String, dynamic>{
    'background': json['background'],
    'foreground': json['foreground'],
    'cursor': json['cursor'],
    'black': json['color_01'],
    'red': json['color_02'],
    'green': json['color_03'],
    'yellow': json['color_04'],
    'blue': json['color_05'],
    'magenta': json['color_06'],
    'cyan': json['color_07'],
    'white': json['color_08'],
    'brightBlack': json['color_09'],
    'brightRed': json['color_10'],
    'brightGreen': json['color_11'],
    'brightYellow': json['color_12'],
    'brightBlue': json['color_13'],
    'brightMagenta': json['color_14'],
    'brightCyan': json['color_15'],
    'brightWhite': json['color_16'],
  };
  return terminalThemeFromJson(xterm);
}
