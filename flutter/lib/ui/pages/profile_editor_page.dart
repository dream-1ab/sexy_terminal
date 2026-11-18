import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import '../components/session_editor_sheet.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key, required this.profile});

  final WorkspaceProfile profile;

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _appState = AppState();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _appState.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.profile.name = name;
    await _appState.profileStore.saveProfile(widget.profile);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _editSession(SessionProfile session) async {
    final updated = await showSessionEditorSheet(context, session);
    if (updated == null || !mounted) return;
    final index = widget.profile.sessions.indexWhere(
      (item) => item.id == session.id,
    );
    if (index >= 0) setState(() => widget.profile.sessions[index] = updated);
  }

  Future<void> _addSession() async {
    final number = widget.profile.sessions.length + 1;
    final draft = SessionProfile(
      id: '${widget.profile.id}-session-$number',
      name: 'Terminal $number',
    );
    final session = await showSessionEditorSheet(context, draft);
    if (session != null && mounted) {
      setState(() => widget.profile.sessions.add(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Container(
      color: theme.canvasColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => Navigator.of(context).pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, size: 18),
                    SizedBox(width: 2),
                    Text('Back'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit workspace profile',
                  style: MacosTheme.of(context).typography.title2,
                ),
              ),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: _save,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Save'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MacosTextField(
            controller: _nameController,
            placeholder: 'Profile name',
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Terminal sessions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: _addSession,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 6),
                    Text('Add session'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final session in widget.profile.sessions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.canvasColor,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: session.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${session.shell ?? 'Default shell'}  |  ${session.workingDirectory ?? 'Current directory'}',
                          style: theme.typography.subheadline,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: () => _editSession(session),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 6),
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: () => setState(
                          () => widget.profile.sessions.remove(session),
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionEditorDialog extends StatefulWidget {
  const _SessionEditorDialog({required this.session});

  final SessionProfile session;

  @override
  State<_SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<_SessionEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _shell;
  late final TextEditingController _directory;
  late final TextEditingController _commands;
  var _color = const Color(0xff00b0ff);

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _name = TextEditingController(text: session.name);
    _shell = TextEditingController(text: session.shell ?? '');
    _directory = TextEditingController(text: session.workingDirectory ?? '');
    _commands = TextEditingController(text: session.startupCommands.join('\n'));
    _color = session.color;
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
    final session = widget.session;
    session.name = _name.text.trim().isEmpty ? 'Terminal' : _name.text.trim();
    session.shell = _shell.text.trim().isEmpty ? null : _shell.text.trim();
    session.workingDirectory = _directory.text.trim().isEmpty
        ? null
        : _directory.text.trim();
    session.startupCommands = _commands.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    session.color = _color;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    const colors = [
      Color(0xff00b0ff), // Electric blue
      Color(0xff00e5ff), // Cyan
      Color(0xff00e676), // Green
      Color(0xff76ff03), // Lime
      Color(0xffffea00), // Yellow
      Color(0xffff9100), // Orange
      Color(0xffff3d00), // Coral
      Color(0xffff1744), // Red
      Color(0xffff4081), // Pink
      Color(0xffd500f9), // Magenta
      Color(0xff651fff), // Purple
      Color(0xff3d5afe), // Indigo
    ];
    return MacosSheet(
      child: SizedBox(
        width: 520,
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
                  placeholderStyle: theme.typography.body.copyWith(
                    color: MacosColors.placeholderTextColor,
                  ),
                ),
                MacosTextField(
                  controller: _shell,
                  placeholder: 'Shell executable (default shell)',
                  style: theme.typography.body,
                  placeholderStyle: theme.typography.body.copyWith(
                    color: MacosColors.placeholderTextColor,
                  ),
                ),
                MacosTextField(
                  controller: _directory,
                  placeholder: 'Working directory (current directory)',
                  style: theme.typography.body,
                  placeholderStyle: theme.typography.body.copyWith(
                    color: MacosColors.placeholderTextColor,
                  ),
                ),
                MacosTextField(
                  controller: _commands,
                  minLines: 4,
                  maxLines: 8,
                  placeholder: 'Startup commands (one command per line)',
                  style: theme.typography.body,
                  placeholderStyle: theme.typography.body.copyWith(
                    color: MacosColors.placeholderTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Session color',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in colors)
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
      ),
    );
  }
}
