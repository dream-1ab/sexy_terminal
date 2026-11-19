import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart' as app_provider;

import '../../app_state.dart';
import '../../profile_models.dart';
import '../components/app_context_menu.dart';
import 'profile_editor_page.dart';
import 'terminal_workspace_page.dart';

class ProfileHomePage extends StatefulWidget {
  const ProfileHomePage({super.key, this.onOpenWorkspace});

  final ValueChanged<String>? onOpenWorkspace;

  @override
  State<ProfileHomePage> createState() => _ProfileHomePageState();
}

class _ProfileHomePageState extends State<ProfileHomePage> {
  static const _contentBackground = Color.fromRGBO(18, 19, 20, 1);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createProfile() async {
    final appState = context.read<AppState>();
    final profile = await appState.createDefaultProfile();
    if (!mounted) return;
    setState(() {});
    _openProfile(profile);
  }

  void _openProfile(WorkspaceProfile profile) {
    final openWorkspace = widget.onOpenWorkspace;
    if (openWorkspace != null) {
      openWorkspace(profile.id);
      return;
    }
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(dockManagerProvider.notifier).clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => app_provider.ChangeNotifierProvider(
          create: (_) => WorkspaceRuntimeState(
            appState: context.read<AppState>(),
            workspaceId: profile.id,
          ),
          child: TerminalWorkspacePage(workspaceId: profile.id),
        ),
      ),
    );
  }

  Future<void> _edit(WorkspaceProfile profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditorPage(profile: profile)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _duplicate(WorkspaceProfile profile) async {
    await context.read<AppState>().duplicateProfile(profile);
    if (mounted) setState(() {});
  }

  void _showProfileMenu(WorkspaceProfile profile, Offset globalPosition) {
    showAppContextMenu(
      context,
      globalPosition: globalPosition,
      actions: [
        AppContextMenuAction(label: 'Edit', onSelected: () => _edit(profile)),
        AppContextMenuAction(
          label: 'Duplicate',
          onSelected: () => _duplicate(profile),
        ),
        AppContextMenuAction(
          label: 'Delete',
          onSelected: () => _delete(profile),
        ),
      ],
    );
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
    await context.read<AppState>().saveProfile(profile);
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
    final appState = context.read<AppState>();
    await appState.deleteProfile(profile.id);
    appState.removeProfile(profile);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profiles = appState.profiles;
    if (profiles.isEmpty) {
      return ColoredBox(
        color: _contentBackground,
        child: _EmptyWorkspaceState(onCreate: _createProfile),
      );
    }
    return ColoredBox(
      color: _contentBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(56, 42, 56, 32),
        children: [
          Text(
            'Workspace Manager',
            style: MacosTheme.of(context).typography.largeTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Open a workspace or create one for a project.',
            style: MacosTheme.of(context).typography.subheadline,
          ),
          const SizedBox(height: 34),
          Text('Workspaces', style: MacosTheme.of(context).typography.title2),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 31, 33, 1),
              border: Border.all(color: const Color(0xff34373d)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                for (var index = 0; index < profiles.length; index++)
                  _WorkspaceListRow(
                    profile: profiles[index],
                    running: appState.activatedWorkspaceIds.contains(
                      profiles[index].id,
                    ),
                    onTap: () => _openProfile(profiles[index]),
                    onMenu: (position) =>
                        _showProfileMenu(profiles[index], position),
                    showDivider: index < profiles.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: PushButton(
              controlSize: ControlSize.regular,
              onPressed: _createProfile,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 7),
                  Text('New workspace'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceListRow extends StatefulWidget {
  const _WorkspaceListRow({
    required this.profile,
    required this.running,
    required this.onTap,
    required this.onMenu,
    required this.showDivider,
  });

  final WorkspaceProfile profile;
  final bool running;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;
  final bool showDivider;

  @override
  State<_WorkspaceListRow> createState() => _WorkspaceListRowState();
}

class _WorkspaceListRowState extends State<_WorkspaceListRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final iconColor = widget.profile.sessions.isEmpty
        ? const Color(0xff8aa4c2)
        : widget.profile.sessions.first.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => widget.onMenu(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hovered ? const Color.fromRGBO(48, 50, 54, 1) : null,
          padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.workspaces_outlined, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.profile.sessions.length} terminal sessions',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.typography.caption1.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.running)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        'Running',
                        style: TextStyle(
                          color: Color(0xff68c78a),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ContextMenuButton(onPressedAt: widget.onMenu),
                ],
              ),
              if (widget.showDivider)
                const Padding(
                  padding: EdgeInsets.only(top: 13),
                  child: Divider(height: 1, color: Color(0xff34373d)),
                ),
            ],
          ),
        ),
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
