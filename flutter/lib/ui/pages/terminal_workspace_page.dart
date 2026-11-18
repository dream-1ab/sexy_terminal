import 'dart:async';

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
  OverlayEntry? _tabMenu;

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
      closable: true,
      onClose: () => _closeTerminal(id),
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

  Future<void> _reloadTerminal(String panelId) async {
    final definition = widget.profile.sessions
        .where((session) => session.id == panelId)
        .firstOrNull;
    if (definition == null) return;
    _appState.sessions.remove(panelId)?.dispose();
    _dockManager.updatePanel(_terminalPanel(definition));
  }

  Future<void> _closeTerminal(String panelId) async {
    _appState.sessions.remove(panelId)?.dispose();
    widget.profile.sessions.removeWhere((session) => session.id == panelId);
    _dockManager.removePanel(panelId);
    await _appState.profileStore.saveProfile(widget.profile);
  }

  void _showTabMenu(String panelId, Offset globalPosition) {
    _tabMenu?.remove();
    final overlay = Overlay.of(context);
    final localPosition = (overlay.context.findRenderObject() as RenderBox)
        .globalToLocal(globalPosition);
    _tabMenu = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissTabMenu,
            ),
          ),
          Positioned(
            left: localPosition.dx,
            top: localPosition.dy,
            child: _TabContextMenu(
              onEdit: () {
                _dismissTabMenu();
                _editTerminal(panelId);
              },
              onReload: () {
                _dismissTabMenu();
                _reloadTerminal(panelId);
              },
              onClose: () {
                _dismissTabMenu();
                _closeTerminal(panelId);
              },
            ),
          ),
        ],
      ),
    );
    overlay.insert(_tabMenu!);
  }

  void _dismissTabMenu() {
    _tabMenu?.remove();
    _tabMenu = null;
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
    _dismissTabMenu();
    if (widget.initialize) {
      unawaited(_appState.profileStore.flushProfile(widget.profile));
    }
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
          headerContentBuilder:
              (
                context,
                panel,
                index,
                isActive,
                icon,
                title,
                textColor,
                onTap,
                onClose,
              ) {
                return _WorkspaceTabHeaderContent(
                  panel: panel,
                  icon: icon,
                  title: title,
                  textColor: textColor,
                  onClose: onClose,
                  onMenuRequested: (position) =>
                      _showTabMenu(panel.id, position),
                );
              },
        ),
        child: const DockArea(),
      ),
    );
  }
}

class _WorkspaceTabHeaderContent extends StatelessWidget {
  const _WorkspaceTabHeaderContent({
    required this.panel,
    required this.icon,
    required this.title,
    required this.textColor,
    required this.onClose,
    required this.onMenuRequested,
  });

  final DockPanel panel;
  final IconData? icon;
  final String title;
  final Color textColor;
  final VoidCallback? onClose;
  final ValueChanged<Offset> onMenuRequested;

  @override
  Widget build(BuildContext context) {
    final isWelcomePanel = panel.id == 'welcome';
    return GestureDetector(
      onSecondaryTapDown: isWelcomePanel
          ? null
          : (details) => onMenuRequested(details.globalPosition),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(title, style: TextStyle(color: textColor, fontSize: 12)),
          if (!isWelcomePanel) ...[
            const SizedBox(width: 8),
            _TabMenuButton(onPressedAt: onMenuRequested, color: textColor),
          ],
          if (!isWelcomePanel && onClose != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 14,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabMenuButton extends StatelessWidget {
  const _TabMenuButton({required this.onPressedAt, required this.color});
  final ValueChanged<Offset> onPressedAt;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (details) => onPressedAt(details.globalPosition),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Icon(
        Icons.more_vert,
        size: 16,
        color: color.withValues(alpha: 0.7),
      ),
    ),
  );
}

class _TabContextMenu extends StatelessWidget {
  const _TabContextMenu({
    required this.onEdit,
    required this.onReload,
    required this.onClose,
  });
  final VoidCallback onEdit;
  final VoidCallback onReload;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.canvasColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabContextMenuItem(label: 'Edit', onTap: onEdit),
          _TabContextMenuItem(label: 'Reload', onTap: onReload),
          _TabContextMenuItem(label: 'Close', onTap: onClose),
        ],
      ),
    );
  }
}

class _TabContextMenuItem extends StatelessWidget {
  const _TabContextMenuItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    ),
  );
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
