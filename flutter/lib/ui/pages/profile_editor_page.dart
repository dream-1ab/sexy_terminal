import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../profile_models.dart';

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
    await showDialog<void>(
      context: context,
      builder: (_) => _SessionEditorDialog(session: session),
    );
    if (mounted) setState(() {});
  }

  void _addSession() {
    final number = widget.profile.sessions.length + 1;
    final session = SessionProfile(
      id: '${widget.profile.id}-session-$number',
      name: 'Terminal $number',
    );
    setState(() => widget.profile.sessions.add(session));
    _editSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      appBar: AppBar(
        title: const Text('Edit workspace profile'),
        backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
        actions: [
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Profile name'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terminal sessions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ElevatedButton.icon(
                onPressed: _addSession,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add session'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final session in widget.profile.sessions)
            Card(
              color: const Color.fromRGBO(18, 19, 20, 1),
              child: ListTile(
                leading: Icon(Icons.terminal, color: session.color),
                title: Text(session.name),
                subtitle: Text('${session.shell ?? 'Default shell'}  |  ${session.workingDirectory ?? 'Current directory'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(onPressed: () => _editSession(session), child: const Text('Edit')),
                    const SizedBox(width: 6),
                    ElevatedButton(onPressed: () => setState(() => widget.profile.sessions.remove(session)), child: const Text('Remove')),
                  ],
                ),
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
  var _color = const Color(0xff293244);

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
    session.workingDirectory = _directory.text.trim().isEmpty ? null : _directory.text.trim();
    session.startupCommands = _commands.text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    session.color = _color;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xff293244),
      Color(0xff24506b),
      Color(0xff274e3a),
      Color(0xff356859),
      Color(0xff5a3c2e),
      Color(0xff7a4b32),
      Color(0xff4b315d),
      Color(0xff6b3f70),
      Color(0xff5b3d5c),
      Color(0xff3d465c),
      Color(0xff536a45),
      Color(0xff6a5d32),
    ];
    return AlertDialog(
      title: const Text('Edit terminal session'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Session name')),
              TextField(controller: _shell, decoration: const InputDecoration(labelText: 'Shell executable', hintText: 'Default shell')),
              TextField(controller: _directory, decoration: const InputDecoration(labelText: 'Working directory', hintText: 'Current directory')),
              TextField(controller: _commands, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Startup commands', hintText: 'One command per line')),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text('Session color', style: Theme.of(context).textTheme.labelLarge)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in colors)
                    InkWell(
                      onTap: () => setState(() => _color = color),
                      borderRadius: BorderRadius.circular(4),
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
                            ? const Icon(Icons.check, size: 17, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
