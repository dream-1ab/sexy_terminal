import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import '../components/session_editor_sheet.dart';
import 'terminal_pane.dart';

class TerminalWorkspacePage extends ConsumerStatefulWidget {
  const TerminalWorkspacePage({
    super.key,
    required this.profile,
    this.initialize = true,
  });

  final WorkspaceProfile profile;
  final bool initialize;

  @override
  ConsumerState<TerminalWorkspacePage> createState() =>
      _TerminalWorkspacePageState();
}

class _TerminalWorkspacePageState extends ConsumerState<TerminalWorkspacePage> {
  final _appState = AppState();
  late final DockManager _dockManager;

  @override
  void initState() {
    super.initState();
    _dockManager = ref.read(dockManagerProvider.notifier);
    if (!widget.initialize) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeWorkspace();
    });
  }

  void _initializeWorkspace() {
    final savedLayout = widget.profile.dockLayout;
    final panels = <DockPanel>[_welcomePanel()];
    for (final definition in widget.profile.sessions) {
      panels.add(_terminalPanel(definition));
    }

    for (final panel in panels) {
      _dockManager.registerPanel(panel);
    }
    if (savedLayout != null) {
      _dockManager.restoreLayout(savedLayout);
      for (final panel in panels) {
        if (!_dockManager.containsPanel(panel.id)) {
          _dockManager.addPanel(panel);
        }
      }
    } else {
      for (final panel in panels) {
        _dockManager.addPanel(panel);
      }
    }
    _dockManager.setLayoutChangeListener(_saveLayout);
    _saveLayout(_dockManager.exportLayout());
  }

  DockPanel _terminalPanel(
    SessionProfile definition, {
    TerminalSession? existingSession,
  }) {
    final id = definition.id;
    final session =
        existingSession ?? _appState.createSession(id, definition: definition);
    return DockPanel(
      id: id,
      title: definition.name,
      icon: Icons.terminal,
      closable: false,
      builder: (_) => TerminalPane(key: ValueKey(id), session: session),
    );
  }

  Future<void> _addTerminal() async {
    final number = widget.profile.sessions.length + 1;
    final definition = SessionProfile(
      id: '${widget.profile.id}-session-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Terminal $number',
    );
    widget.profile.sessions.add(definition);
    final panel = _terminalPanel(definition);
    _dockManager.addPanel(panel);
    await _appState.profileStore.saveProfile(widget.profile);
  }

  Future<void> _editTerminal(String panelId) async {
    final matches = widget.profile.sessions.where(
      (session) => session.id == panelId,
    );
    if (matches.isEmpty) return;
    final definition = matches.first;
    final updated = await showSessionEditorSheet(context, definition);
    if (updated == null || !mounted) return;
    final index = widget.profile.sessions.indexWhere(
      (session) => session.id == panelId,
    );
    widget.profile.sessions[index] = updated;
    _dockManager.updatePanel(
      _terminalPanel(updated, existingSession: _appState.sessions[panelId]),
    );
    await _appState.profileStore.saveProfile(widget.profile);
  }

  Future<void> _saveLayout(Map<String, dynamic>? layout) async {
    widget.profile.dockLayout = layout;
    await _appState.profileStore.saveProfile(widget.profile);
  }

  DockPanel _welcomePanel() {
    return DockPanel(
      id: 'welcome',
      title: 'Welcome',
      icon: Icons.waving_hand_outlined,
      closable: false,
      builder: (_) => _WelcomePanel(onPressed: _addTerminal),
    );
  }

  @override
  void dispose() {
    _dockManager.setLayoutChangeListener(null);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DockTheme(
        data: DockThemeData(
          backgroundColor: const Color.fromRGBO(18, 19, 20, 1),
          tabBarColor: const Color.fromRGBO(43, 43, 43, 1),
          activeTabColor: const Color.fromRGBO(18, 19, 20, 1),
          inactiveTabColor: Colors.transparent,
          dividerColor: Colors.transparent,
          tabTextColor: const Color(0xffb8c0cc),
          activeTabTextColor: Colors.white,
          dividerThickness: 4,
          tabHeight: 34,
          tabShape: DockTabShape.pill,
          tabPadding: const EdgeInsets.only(left: 14, top: 0, right: 14),
          tabBuilder: (context, panel, index, isActive, child, onTap, onClose) {
            if (panel.id == 'welcome') return child;
            return GestureDetector(
              onSecondaryTap: () => _editTerminal(panel.id),
              child: child,
            );
          },
        ),
        child: const DockArea(),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PushButton(
        controlSize: ControlSize.regular,
        onPressed: onPressed,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16),
            SizedBox(width: 6),
            Text('New terminal'),
          ],
        ),
      ),
    );
  }
}
