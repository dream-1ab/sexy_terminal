import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import '../../theme_presets.dart';
import '../components/app_context_menu.dart';
import '../components/session_editor_sheet.dart';
import '../components/session_icons.dart';
import '../components/session_theme_dialog.dart';
import '../components/terminal_theme_gallery.dart';

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

  Future<void> _editSessionTheme(SessionProfile session) async {
    final result = await showSessionThemeDialog(context, session);
    if (result == null || !mounted) return;
    setState(() => session.terminalTheme = result.custom ? result.theme : null);
  }

  Future<void> _editWorkspaceTheme() async {
    final selected = await showTerminalThemeGallery(
      context,
      presets: ThemePresetStore.instance.presets,
    );
    if (selected == null || !mounted) return;
    setState(() => widget.profile.terminalTheme = selected.theme);
  }

  void _duplicateSession(SessionProfile session) {
    final duplicate = SessionProfile(
      id: '${widget.profile.id}-session-${DateTime.now().microsecondsSinceEpoch}',
      name: '${session.name} copy',
      color: session.color,
      icon: session.icon,
      appearance: session.appearance,
      terminalTheme: session.terminalTheme,
      shell: session.shell,
      workingDirectory: session.workingDirectory,
      startupCommands: List.of(session.startupCommands),
    );
    setState(() => widget.profile.sessions.add(duplicate));
  }

  void _removeSession(SessionProfile session) {
    setState(() => widget.profile.sessions.remove(session));
  }

  void _showSessionMenu(SessionProfile session, Offset globalPosition) {
    showAppContextMenu(
      context,
      globalPosition: globalPosition,
      actions: [
        AppContextMenuAction(
          label: 'Edit',
          onSelected: () => _editSession(session),
        ),
        AppContextMenuAction(
          label: 'Theme…',
          onSelected: () => _editSessionTheme(session),
        ),
        AppContextMenuAction(
          label: 'Duplicate',
          onSelected: () => _duplicateSession(session),
        ),
        AppContextMenuAction(
          label: 'Remove',
          onSelected: () => _removeSession(session),
        ),
      ],
    );
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.profile.terminalTheme == null
                      ? 'Terminal theme: use global'
                      : 'Terminal theme: workspace override',
                ),
              ),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: _editWorkspaceTheme,
                child: const Text('Choose theme…'),
              ),
              if (widget.profile.terminalTheme != null) ...[
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () =>
                      setState(() => widget.profile.terminalTheme = null),
                  child: const Text('Use global'),
                ),
              ],
            ],
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
            GestureDetector(
              onSecondaryTapDown: (details) =>
                  _showSessionMenu(session, details.globalPosition),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.canvasColor,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Icon(sessionIcon(session.icon), color: session.color),
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
                    ContextMenuButton(
                      onPressedAt: (position) =>
                          _showSessionMenu(session, position),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
