import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../profile_models.dart';
import 'session_icons.dart';

Future<SessionProfile?> showSessionEditorSheet(
  BuildContext context,
  SessionProfile session,
) => showMacosSheet<SessionProfile>(
  context: context,
  barrierDismissible: true,
  builder: (_) => Center(
    child: MacosSheet(
      insetPadding: EdgeInsets.zero,
      child: SessionEditorSheet(session: session),
    ),
  ),
);

class SessionEditorSheet extends StatefulWidget {
  const SessionEditorSheet({super.key, required this.session});

  final SessionProfile session;

  @override
  State<SessionEditorSheet> createState() => _SessionEditorSheetState();
}

class _SessionEditorSheetState extends State<SessionEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _shell;
  late final TextEditingController _directory;
  late final TextEditingController _commands;
  late Color _color;
  late String _icon;

  static const _colors = [
    Color(0xff00b0ff),
    Color(0xff00e5ff),
    Color(0xff00e676),
    Color(0xff76ff03),
    Color(0xffffea00),
    Color(0xffff9100),
    Color(0xffff3d00),
    Color(0xffff1744),
    Color(0xffff4081),
    Color(0xffd500f9),
    Color(0xff651fff),
    Color(0xff3d5afe),
  ];

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _name = TextEditingController(text: session.name);
    _shell = TextEditingController(text: session.shell ?? '');
    _directory = TextEditingController(text: session.workingDirectory ?? '');
    _commands = TextEditingController(text: session.startupCommands.join('\n'));
    _color = session.color;
    _icon = session.icon;
  }

  @override
  void dispose() {
    _name.dispose();
    _shell.dispose();
    _directory.dispose();
    _commands.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      SessionProfile(
        id: widget.session.id,
        name: _name.text.trim().isEmpty ? 'Terminal' : _name.text.trim(),
        color: _color,
        icon: _icon,
        terminalTheme: widget.session.terminalTheme,
        shell: _shell.text.trim().isEmpty ? null : _shell.text.trim(),
        workingDirectory: _directory.text.trim().isEmpty
            ? null
            : _directory.text.trim(),
        startupCommands: _commands.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final placeholderStyle = theme.typography.body.copyWith(
      color: MacosColors.placeholderTextColor,
    );
    return SizedBox(
      width: 560,
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MacosTextField(
                controller: _name,
                placeholder: 'Session name',
                style: theme.typography.body,
                placeholderStyle: placeholderStyle,
              ),
              MacosTextField(
                controller: _shell,
                placeholder: 'Shell executable (default shell)',
                style: theme.typography.body,
                placeholderStyle: placeholderStyle,
              ),
              MacosTextField(
                controller: _directory,
                placeholder: 'Working directory (current directory)',
                style: theme.typography.body,
                placeholderStyle: placeholderStyle,
              ),
              MacosTextField(
                controller: _commands,
                minLines: 4,
                maxLines: 8,
                placeholder: 'Startup commands (one command per line)',
                style: theme.typography.body,
                placeholderStyle: placeholderStyle,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Session color', style: theme.typography.headline),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _colors)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _color.value == color.value
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: _color.value == color.value
                              ? const Icon(
                                  Icons.check,
                                  size: 17,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Session icon', style: theme.typography.headline),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in sessionIcons.entries)
                    GestureDetector(
                      onTap: () => setState(() => _icon = entry.key),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _icon == entry.key
                                  ? _color
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 18,
                            color: _icon == entry.key ? _color : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
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
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
