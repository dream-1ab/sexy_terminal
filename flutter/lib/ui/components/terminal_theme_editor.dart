import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:xterm/xterm.dart';

/// Edits an immutable xterm [TerminalTheme].
///
/// The widget owns no persistence or application state. Its parent receives a
/// complete replacement theme through [onChanged], making it suitable for both
/// global settings and per-session overrides.
class TerminalThemeEditor extends StatelessWidget {
  const TerminalThemeEditor({
    super.key,
    required this.theme,
    required this.onChanged,
  });

  final TerminalTheme theme;
  final ValueChanged<TerminalTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ThemeColorSection(
          title: 'Terminal',
          entries: [
            _ThemeColorEntry(
              'Background',
              theme.background,
              (color) => onChanged(theme.copyWith(background: color)),
            ),
            _ThemeColorEntry(
              'Foreground',
              theme.foreground,
              (color) => onChanged(theme.copyWith(foreground: color)),
            ),
            _ThemeColorEntry(
              'Cursor',
              theme.cursor,
              (color) => onChanged(theme.copyWith(cursor: color)),
            ),
            _ThemeColorEntry(
              'Selection',
              theme.selection,
              (color) => onChanged(theme.copyWith(selection: color)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ThemeColorSection(
          title: 'ANSI colors',
          entries: [
            _ThemeColorEntry(
              'Black',
              theme.black,
              (color) => onChanged(theme.copyWith(black: color)),
            ),
            _ThemeColorEntry(
              'Red',
              theme.red,
              (color) => onChanged(theme.copyWith(red: color)),
            ),
            _ThemeColorEntry(
              'Green',
              theme.green,
              (color) => onChanged(theme.copyWith(green: color)),
            ),
            _ThemeColorEntry(
              'Yellow',
              theme.yellow,
              (color) => onChanged(theme.copyWith(yellow: color)),
            ),
            _ThemeColorEntry(
              'Blue',
              theme.blue,
              (color) => onChanged(theme.copyWith(blue: color)),
            ),
            _ThemeColorEntry(
              'Magenta',
              theme.magenta,
              (color) => onChanged(theme.copyWith(magenta: color)),
            ),
            _ThemeColorEntry(
              'Cyan',
              theme.cyan,
              (color) => onChanged(theme.copyWith(cyan: color)),
            ),
            _ThemeColorEntry(
              'White',
              theme.white,
              (color) => onChanged(theme.copyWith(white: color)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ThemeColorSection(
          title: 'Bright ANSI colors',
          entries: [
            _ThemeColorEntry(
              'Bright black',
              theme.brightBlack,
              (color) => onChanged(theme.copyWith(brightBlack: color)),
            ),
            _ThemeColorEntry(
              'Bright red',
              theme.brightRed,
              (color) => onChanged(theme.copyWith(brightRed: color)),
            ),
            _ThemeColorEntry(
              'Bright green',
              theme.brightGreen,
              (color) => onChanged(theme.copyWith(brightGreen: color)),
            ),
            _ThemeColorEntry(
              'Bright yellow',
              theme.brightYellow,
              (color) => onChanged(theme.copyWith(brightYellow: color)),
            ),
            _ThemeColorEntry(
              'Bright blue',
              theme.brightBlue,
              (color) => onChanged(theme.copyWith(brightBlue: color)),
            ),
            _ThemeColorEntry(
              'Bright magenta',
              theme.brightMagenta,
              (color) => onChanged(theme.copyWith(brightMagenta: color)),
            ),
            _ThemeColorEntry(
              'Bright cyan',
              theme.brightCyan,
              (color) => onChanged(theme.copyWith(brightCyan: color)),
            ),
            _ThemeColorEntry(
              'Bright white',
              theme.brightWhite,
              (color) => onChanged(theme.copyWith(brightWhite: color)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ThemeColorSection(
          title: 'Search highlights',
          entries: [
            _ThemeColorEntry(
              'Match background',
              theme.searchHitBackground,
              (color) => onChanged(theme.copyWith(searchHitBackground: color)),
            ),
            _ThemeColorEntry(
              'Current match',
              theme.searchHitBackgroundCurrent,
              (color) =>
                  onChanged(theme.copyWith(searchHitBackgroundCurrent: color)),
            ),
            _ThemeColorEntry(
              'Match foreground',
              theme.searchHitForeground,
              (color) => onChanged(theme.copyWith(searchHitForeground: color)),
            ),
          ],
        ),
      ],
    );
  }
}

extension TerminalThemeCopyWith on TerminalTheme {
  TerminalTheme copyWith({
    Color? cursor,
    Color? selection,
    Color? foreground,
    Color? background,
    Color? black,
    Color? red,
    Color? green,
    Color? yellow,
    Color? blue,
    Color? magenta,
    Color? cyan,
    Color? white,
    Color? brightBlack,
    Color? brightRed,
    Color? brightGreen,
    Color? brightYellow,
    Color? brightBlue,
    Color? brightMagenta,
    Color? brightCyan,
    Color? brightWhite,
    Color? searchHitBackground,
    Color? searchHitBackgroundCurrent,
    Color? searchHitForeground,
  }) => TerminalTheme(
    cursor: cursor ?? this.cursor,
    selection: selection ?? this.selection,
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    black: black ?? this.black,
    white: white ?? this.white,
    red: red ?? this.red,
    green: green ?? this.green,
    yellow: yellow ?? this.yellow,
    blue: blue ?? this.blue,
    magenta: magenta ?? this.magenta,
    cyan: cyan ?? this.cyan,
    brightBlack: brightBlack ?? this.brightBlack,
    brightRed: brightRed ?? this.brightRed,
    brightGreen: brightGreen ?? this.brightGreen,
    brightYellow: brightYellow ?? this.brightYellow,
    brightBlue: brightBlue ?? this.brightBlue,
    brightMagenta: brightMagenta ?? this.brightMagenta,
    brightCyan: brightCyan ?? this.brightCyan,
    brightWhite: brightWhite ?? this.brightWhite,
    searchHitBackground: searchHitBackground ?? this.searchHitBackground,
    searchHitBackgroundCurrent:
        searchHitBackgroundCurrent ?? this.searchHitBackgroundCurrent,
    searchHitForeground: searchHitForeground ?? this.searchHitForeground,
  );
}

class _ThemeColorEntry {
  const _ThemeColorEntry(this.label, this.color, this.onChanged);

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
}

class _ThemeColorSection extends StatelessWidget {
  const _ThemeColorSection({required this.title, required this.entries});

  final String title;
  final List<_ThemeColorEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.typography.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in entries) _ThemeColorTile(entry: entry),
          ],
        ),
      ],
    );
  }
}

class _ThemeColorTile extends StatelessWidget {
  const _ThemeColorTile({required this.entry});

  final _ThemeColorEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return GestureDetector(
      onTap: () async {
        final color = await _showThemeColorPicker(context, entry.color);
        if (color != null) entry.onChanged(color);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: entry.color,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label, overflow: TextOverflow.ellipsis),
                    Text(
                      _colorHex(entry.color),
                      style: theme.typography.caption1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _colorHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

Future<Color?> _showThemeColorPicker(
  BuildContext context,
  Color initialColor,
) => showMacosSheet<Color>(
  context: context,
  barrierDismissible: true,
  builder: (_) => Center(
    child: MacosSheet(
      insetPadding: EdgeInsets.zero,
      child: _ThemeColorPickerDialog(initialColor: initialColor),
    ),
  ),
);

class _ThemeColorPickerDialog extends StatefulWidget {
  const _ThemeColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ThemeColorPickerDialog> createState() =>
      _ThemeColorPickerDialogState();
}

class _ThemeColorPickerDialogState extends State<_ThemeColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose color',
              style: MacosTheme.of(context).typography.title2,
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) =>
                    setState(() => _selectedColor = color),
                enableAlpha: true,
                displayThumbColor: true,
                labelTypes: const [],
                hexInputBar: true,
                portraitOnly: true,
                colorPickerWidth: 360,
                pickerAreaBorderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () => Navigator.pop(context, _selectedColor),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
