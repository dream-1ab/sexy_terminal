import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import 'profile_editor_page.dart';
import 'terminal_workspace_page.dart';

class ProfileHomePage extends StatefulWidget {
  const ProfileHomePage({super.key});

  @override
  State<ProfileHomePage> createState() => _ProfileHomePageState();
}

class _ProfileHomePageState extends State<ProfileHomePage> {
  final _appState = AppState();
  var _loading = true;

  static const _contentBackground = Color.fromRGBO(18, 19, 20, 1);
  static const _surfaceBackground = Color.fromRGBO(43, 43, 43, 1);

  @override
  void initState() {
    super.initState();
    _appState.loadProfiles().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _createProfile() async {
    final profile = await _appState.createDefaultProfile();
    if (!mounted) return;
    setState(() {});
    _openProfile(profile);
  }

  void _openProfile(WorkspaceProfile profile) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(dockManagerProvider.notifier).clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalWorkspacePage(profile: profile),
      ),
    );
  }

  Future<void> _edit(WorkspaceProfile profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditorPage(profile: profile)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _rename(WorkspaceProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final value = await showMacosSheet<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _SingleFieldSheet(title: 'Rename profile', controller: controller),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    profile.name = value.trim();
    await _appState.profileStore.saveProfile(profile);
    if (mounted) setState(() {});
  }

  Future<void> _delete(WorkspaceProfile profile) async {
    final confirmed = await showMacosSheet<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ConfirmSheet(
        title: 'Delete profile?',
        message: 'Delete "${profile.name}"?',
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
    if (_loading) {
      return const ColoredBox(
        color: _contentBackground,
        child: Center(child: ProgressCircle()),
      );
    }
    if (_appState.profiles.isEmpty) {
      return ColoredBox(
        color: _contentBackground,
        child: _EmptyWorkspaceState(onCreate: _createProfile),
      );
    }
    return ColoredBox(
      color: _contentBackground,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              itemCount: _appState.profiles.length,
              itemBuilder: (context, index) {
                final profile = _appState.profiles[index];
                final color = profile.sessions.isEmpty
                    ? const Color(0xff8aa4c2)
                    : profile.sessions.first.color;
                return GestureDetector(
                  onSecondaryTap: () => _edit(profile),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openProfile(profile),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceBackground,
                          border: Border.all(color: const Color(0xff3b414b)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.workspaces_outlined, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${profile.sessions.length} terminal sessions',
                                    style: const TextStyle(
                                      color: Color(0xffa9b0bb),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PushButton(
                              controlSize: ControlSize.regular,
                              padding: EdgeInsets.zero,
                              onPressed: () => _edit(profile),
                              child: const Icon(Icons.edit_outlined, size: 16),
                            ),
                            const SizedBox(width: 8),
                            PushButton(
                              controlSize: ControlSize.regular,
                              padding: EdgeInsets.zero,
                              onPressed: () => _delete(profile),
                              child: const Icon(Icons.delete_outline, size: 16),
                            ),
                          ],
                        ),
                      ),
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
              child: PushButton(
                controlSize: ControlSize.regular,
                onPressed: _createProfile,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 6),
                    Text('New workspace profile'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkspaceState extends StatelessWidget {
  const _EmptyWorkspaceState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
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
              const Icon(
                Icons.workspaces_outlined,
                size: 34,
                color: Color(0xffb8c0cc),
              ),
              const SizedBox(height: 14),
              const Text(
                'No workspace profiles',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a profile for a project and its terminal sessions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xffa9b0bb)),
              ),
              const SizedBox(height: 20),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: onCreate,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 6),
                    Text('Create workspace profile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SingleFieldSheet extends StatelessWidget {
  const _SingleFieldSheet({required this.title, required this.controller});
  final String title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MacosSheet(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: MacosTheme.of(context).typography.title2),
          const SizedBox(height: 16),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Profile name',
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
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => MacosSheet(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: MacosTheme.of(context).typography.title2),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
