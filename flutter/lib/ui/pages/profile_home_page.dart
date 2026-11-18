import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import 'terminal_workspace_page.dart';
import 'profile_editor_page.dart';

class ProfileHomePage extends StatefulWidget {
  const ProfileHomePage({super.key});

  @override
  State<ProfileHomePage> createState() => _ProfileHomePageState();
}

class _ProfileHomePageState extends State<ProfileHomePage> {
  final _appState = AppState();
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    await _appState.loadProfiles();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProfile() async {
    final profile = await _appState.createDefaultProfile();
    if (mounted) setState(() {});
    if (mounted) _openProfile(profile);
  }

  void _openProfile(WorkspaceProfile profile) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderScope(
        child: TerminalWorkspacePage(profile: profile),
      ),
    ));
  }

  Future<void> _showProfileMenu(
    WorkspaceProfile profile,
    TapDownDetails details,
  ) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Edit profile')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'color', child: Text('Change color')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileEditorPage(profile: profile)));
        if (mounted) setState(() {});
      case 'rename':
        await _renameProfile(profile);
      case 'color':
        await _changeProfileColor(profile);
      case 'delete':
        await _deleteProfile(profile);
    }
  }

  Future<void> _renameProfile(WorkspaceProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename profile'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    profile.name = name;
    await _appState.profileStore.saveProfile(profile);
    if (mounted) setState(() {});
  }

  Future<void> _changeProfileColor(WorkspaceProfile profile) async {
    const colors = [
      Color(0xff293244),
      Color(0xff274e3a),
      Color(0xff5a3c2e),
      Color(0xff4b315d),
      Color(0xff24506b),
    ];
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile color'),
        content: Wrap(
          spacing: 12,
          children: [
            for (final color in colors)
              IconButton(
                onPressed: () => Navigator.pop(context, color),
                icon: Icon(Icons.circle, color: color, size: 30),
              ),
          ],
        ),
      ),
    );
    if (color == null) return;
    for (final session in profile.sessions) {
      session.color = color;
    }
    await _appState.profileStore.saveProfile(profile);
    if (mounted) setState(() {});
  }

  Future<void> _deleteProfile(WorkspaceProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Delete "${profile.name}"?'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _appState.profileStore.deleteProfile(profile.id);
    _appState.profiles.remove(profile);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      appBar: AppBar(
        title: const Text('Workspace profiles'),
        backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appState.profiles.isEmpty
              ? const _EmptyWorkspaceState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        itemCount: _appState.profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _appState.profiles[index];
                          return GestureDetector(
                            onSecondaryTapDown: (details) => _showProfileMenu(profile, details),
                            child: Card(
                              color: const Color.fromRGBO(18, 19, 20, 1),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(Icons.workspaces_outlined, color: profile.sessions.isEmpty ? null : profile.sessions.first.color),
                                title: Text(profile.name),
                                subtitle: Text('${profile.sessions.length} terminal sessions'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Profile actions',
                                      icon: const Icon(Icons.more_horiz),
                                      onPressed: () => _showProfileMenu(profile, TapDownDetails(globalPosition: Offset.zero)),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => _openProfile(profile),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _createProfile,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New workspace profile'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyWorkspaceState extends StatelessWidget {
  const _EmptyWorkspaceState();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProfileHomePageState>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(18, 19, 20, 1),
            border: Border.all(color: const Color(0xff3b414b)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspaces_outlined, size: 34, color: Color(0xffb8c0cc)),
                const SizedBox(height: 14),
                const Text('No workspace profiles', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Create a profile for a project and its terminal sessions.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xffa9b0bb))),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: state._createProfile,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create workspace profile'),
                  
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
