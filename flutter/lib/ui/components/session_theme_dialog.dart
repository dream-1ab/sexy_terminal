import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:xterm/xterm.dart';

import '../../profile_models.dart';
import '../../theme_presets.dart';
import 'terminal_theme_editor.dart';
import 'terminal_theme_gallery.dart';

class SessionThemeEditResult {
  const SessionThemeEditResult({required this.custom, this.theme});

  final bool custom;
  final TerminalTheme? theme;
}

Future<SessionThemeEditResult?> showSessionThemeDialog(
  BuildContext context,
  SessionProfile session, {
  ValueChanged<TerminalTheme?>? onPreviewTheme,
  TerminalTheme? initialTheme,
}) => showMacosSheet<SessionThemeEditResult>(
  context: context,
  barrierDismissible: true,
  builder: (_) => Center(
    child: MacosSheet(
      insetPadding: EdgeInsets.zero,
      child: _SessionThemeDialog(
        session: session,
        onPreviewTheme: onPreviewTheme,
        initialTheme: initialTheme,
      ),
    ),
  ),
);

class _SessionThemeDialog extends StatefulWidget {
  const _SessionThemeDialog({
    required this.session,
    this.onPreviewTheme,
    this.initialTheme,
  });

  final SessionProfile session;
  final ValueChanged<TerminalTheme?>? onPreviewTheme;
  final TerminalTheme? initialTheme;

  @override
  State<_SessionThemeDialog> createState() => _SessionThemeDialogState();
}

class _SessionThemeDialogState extends State<_SessionThemeDialog> {
  late bool _custom;
  late TerminalTheme _theme;
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _custom = widget.session.terminalTheme != null;
    _theme =
        widget.initialTheme ??
        widget.session.terminalTheme ??
        ThemePresetStore.instance.globalTheme;
  }

  void _preview() {
    widget.onPreviewTheme?.call(_custom ? _theme : null);
  }

  Future<void> _choosePreset() async {
    final preset = await showTerminalThemeGallery(
      context,
      presets: ThemePresetStore.instance.presets,
      selectedPresetId: _selectedPresetId,
    );
    if (preset == null || !mounted) return;
    setState(() {
      _custom = true;
      _selectedPresetId = preset.id;
      _theme = preset.theme;
    });
    _preview();
  }

  Future<void> _customize() async {
    final theme = await showMacosSheet<TerminalTheme>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: MacosSheet(
          insetPadding: EdgeInsets.zero,
          child: _ThemeCustomizeSheet(theme: _theme),
        ),
      ),
    );
    if (theme == null || !mounted) return;
    setState(() {
      _custom = true;
      _selectedPresetId = null;
      _theme = theme;
    });
    _preview();
  }

  @override
  Widget build(BuildContext context) {
    final macosTheme = MacosTheme.of(context);
    return SizedBox(
      width: 540,
      height: 330,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Terminal theme', style: macosTheme.typography.title2),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _custom
                        ? 'This session uses its own theme.'
                        : 'This session follows the global theme.',
                  ),
                ),
                MacosSwitch(
                  value: _custom,
                  onChanged: (value) {
                    setState(() => _custom = value);
                    _preview();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _choosePreset,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Choose theme preset…'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _customize,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16),
                  SizedBox(width: 8),
                  Text('Customize colors…'),
                ],
              ),
            ),
            const Spacer(),
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
                  onPressed: () => Navigator.pop(
                    context,
                    SessionThemeEditResult(custom: _custom, theme: _theme),
                  ),
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

class _ThemeCustomizeSheet extends StatefulWidget {
  const _ThemeCustomizeSheet({required this.theme});

  final TerminalTheme theme;

  @override
  State<_ThemeCustomizeSheet> createState() => _ThemeCustomizeSheetState();
}

class _ThemeCustomizeSheetState extends State<_ThemeCustomizeSheet> {
  late TerminalTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 760,
    height: 650,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customize terminal colors',
            style: MacosTheme.of(context).typography.title2,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: TerminalThemeEditor(
                theme: _theme,
                onChanged: (theme) => setState(() => _theme = theme),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                onPressed: () => Navigator.pop(context, _theme),
                child: const Text('Use colors'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
