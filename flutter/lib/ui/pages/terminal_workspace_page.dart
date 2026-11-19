import 'dart:async';

import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../app_log.dart';
import '../../app_state.dart';
import '../../profile_models.dart';
import '../../window_navigator.dart';
import '../components/session_editor_sheet.dart';
import '../components/session_icons.dart';
import '../components/session_theme_dialog.dart';
import 'terminal_pane.dart';

class TerminalWorkspacePage extends ConsumerStatefulWidget {
  const TerminalWorkspacePage({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<TerminalWorkspacePage> createState() =>
      _TerminalWorkspacePageState();
}

class _TerminalWorkspacePageState extends ConsumerState<TerminalWorkspacePage> {
  late final AppState _appState;
  late final WorkspaceRuntimeState _runtime;
  late final DockManager _dockManager;
  OverlayEntry? _tabMenu;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _runtime = context.read<WorkspaceRuntimeState>();
    _dockManager = ref.read(dockManagerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeWorkspace();
    });
  }

  void _initializeWorkspace() {
    final profile = _runtime.profile;
    final savedLayout = profile.dockLayout;
    appLog(
      AppLogTag.workspace,
      'Initializing workspace "${profile.name}" (${profile.id}) '
      'with ${profile.sessions.length} terminal session(s); '
      'saved layout: ${savedLayout != null}.',
    );
    final panels = <DockPanel>[_welcomePanel()];
    for (final definition in profile.sessions) {
      panels.add(_terminalPanel(definition));
    }

    for (final panel in panels) {
      _dockManager.registerPanel(panel);
    }
    if (savedLayout != null) {
      _dockManager.restoreLayout(savedLayout);
      appLog(AppLogTag.dock, 'Restored saved dock layout for ${profile.id}.');
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
    appLog(AppLogTag.workspace, 'Workspace ${profile.id} initialized.');
  }

  DockPanel _terminalPanel(
    SessionProfile definition, {
    TerminalSession? existingSession,
  }) {
    final id = definition.id;
    final session =
        existingSession ??
        _runtime.createSession(
          id,
          definition: definition,
          resolvedTheme: _appState.resolveTheme(
            sessionTheme: definition.terminalTheme,
            workspaceTheme: _runtime.profile.terminalTheme,
          ),
          resolvedAppearance: _appState.resolveAppearance(
            sessionAppearance: definition.appearance,
            workspaceAppearance: _runtime.profile.appearance,
            sessionTheme: definition.terminalTheme,
            workspaceTheme: _runtime.profile.terminalTheme,
          ),
          followsGlobalTheme:
              definition.terminalTheme == null &&
              _runtime.profile.terminalTheme == null,
        );
    return DockPanel(
      id: id,
      title: definition.name,
      icon: sessionIcon(definition.icon),
      closable: true,
      onClose: () => _closeTerminal(id),
      builder: (_) => TerminalPane(key: ValueKey(id), session: session),
    );
  }

  Future<void> _addTerminal() async {
    final profile = _runtime.profile;
    final number = profile.sessions.length + 1;
    final definition = SessionProfile(
      id: '${profile.id}-session-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Terminal $number',
    );
    profile.sessions.add(definition);
    final panel = _terminalPanel(definition);
    _dockManager.addPanel(panel);
    appLog(
      AppLogTag.dock,
      'Added terminal tab ${definition.id} to ${profile.id}.',
    );
    await _appState.saveProfile(profile);
  }

  Future<void> _editTerminal(String panelId) async {
    final profile = _runtime.profile;
    final matches = profile.sessions.where((session) => session.id == panelId);
    if (matches.isEmpty) return;
    final definition = matches.first;
    final updated = await showSessionEditorSheet(context, definition);
    if (updated == null || !mounted) return;
    final index = profile.sessions.indexWhere(
      (session) => session.id == panelId,
    );
    profile.sessions[index] = updated;
    _runtime.sessions[panelId]?.updateTheme(
      updated.terminalTheme ?? _appState.globalTheme,
    );
    _dockManager.updatePanel(
      _terminalPanel(updated, existingSession: _runtime.sessions[panelId]),
    );
    appLog(AppLogTag.dock, 'Updated terminal tab $panelId in ${profile.id}.');
    await _appState.saveProfile(profile);
  }

  Future<void> _saveLayout(Map<String, dynamic>? layout) async {
    final profile = _runtime.profile;
    profile.dockLayout = layout;
    appLog(
      AppLogTag.dock,
      'Dock layout changed for ${profile.id}; scheduling profile save.',
    );
    await _appState.saveProfile(profile);
  }

  Future<void> _reloadTerminal(String panelId) async {
    final definition = _runtime.profile.sessions
        .where((session) => session.id == panelId)
        .firstOrNull;
    if (definition == null) return;
    appLog(
      AppLogTag.dock,
      'Reloading terminal tab $panelId in ${_runtime.workspaceId}.',
    );
    final previousSession = _runtime.detachSession(panelId);
    previousSession?.terminate();
    _dockManager.updatePanel(_terminalPanel(definition));
    _disposeSessionAfterPanelUpdate(previousSession);
  }

  Future<void> _editTerminalTheme(String panelId) async {
    final definition = _runtime.profile.sessions
        .where((session) => session.id == panelId)
        .firstOrNull;
    if (definition == null) return;
    final runtime = _runtime.sessions[panelId];
    final previousTheme = runtime?.theme.value;
    final result = await showSessionThemeDialog(
      context,
      definition,
      initialTheme: previousTheme,
      onPreviewTheme: (theme) {
        runtime?.updateTheme(
          theme ??
              _appState.resolveTheme(
                workspaceTheme: _runtime.profile.terminalTheme,
              ),
        );
      },
    );
    if (result == null) {
      if (previousTheme != null) runtime?.updateTheme(previousTheme);
      return;
    }
    definition.terminalTheme = result.custom ? result.theme : null;
    await _appState.saveProfile(_runtime.profile);
  }

  Future<void> _closeTerminal(String panelId) async {
    appLog(
      AppLogTag.dock,
      'Closing terminal tab $panelId in ${_runtime.workspaceId}.',
    );
    final session = _runtime.detachSession(panelId);
    session?.terminate();
    _runtime.profile.sessions.removeWhere((session) => session.id == panelId);
    _dockManager.removePanel(panelId);
    _disposeSessionAfterPanelUpdate(session);
    await _appState.saveProfile(_runtime.profile);
  }

  void _disposeSessionAfterPanelUpdate(TerminalSession? session) {
    if (session == null) return;
    appLog(
      AppLogTag.terminal,
      'Scheduling next-frame terminal resource disposal.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLog(AppLogTag.terminal, 'Running terminal resource disposal.');
      session.dispose();
    });
  }

  void _showTabMenu(String panelId, Offset globalPosition) {
    appLog(AppLogTag.dock, 'Opened tab actions for $panelId.');
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
              onTheme: () {
                _dismissTabMenu();
                _editTerminalTheme(panelId);
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
      builder: (_) => _WelcomePanel(
        onPressed: _addTerminal,
        onBackToLauncher: () => WindowNavigator.of(context).openDefault(),
      ),
    );
  }

  @override
  void dispose() {
    appLog(AppLogTag.workspace, 'Disposing workspace ${_runtime.workspaceId}.');
    _dockManager.setLayoutChangeListener(null);
    _dismissTabMenu();
    unawaited(_appState.flushProfile(_runtime.profile));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MacosTheme.of(context).canvasColor,
      body: DockTheme(
        data: DockThemeData(
          backgroundColor: const Color.fromRGBO(18, 19, 20, 1),
          tabBarColor: MacosTheme.of(context).canvasColor,
          activeTabColor: const Color.fromRGBO(18, 19, 20, 1),
          inactiveTabColor: Colors.transparent,
          dividerColor: MacosTheme.of(context).dividerColor,
          tabTextColor: const Color(0xffb8c0cc),
          activeTabTextColor: Colors.white,
          dividerThickness: 8,
          tabHeight: 34,
          borderRadius: BorderRadius.circular(8),
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
        child: Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: const DockArea(),
        ),
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
    required this.onTheme,
    required this.onReload,
    required this.onClose,
  });
  final VoidCallback onEdit;
  final VoidCallback onTheme;
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
          _TabContextMenuItem(label: 'Theme…', onTap: onTheme),
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
  const _WelcomePanel({
    required this.onPressed,
    required this.onBackToLauncher,
  });

  final VoidCallback onPressed;
  final VoidCallback onBackToLauncher;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PushButton(
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
          const SizedBox(height: 12),
          PushButton(
            controlSize: ControlSize.regular,
            onPressed: onBackToLauncher,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 16),
                SizedBox(width: 6),
                Text('Back to launcher'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
