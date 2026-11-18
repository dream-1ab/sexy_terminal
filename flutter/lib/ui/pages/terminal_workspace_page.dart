import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../profile_models.dart';
import 'terminal_pane.dart';

class TerminalWorkspacePage extends ConsumerStatefulWidget {
  const TerminalWorkspacePage({super.key, required this.profile, this.initialize = true});

  final WorkspaceProfile profile;
  final bool initialize;

  @override
  ConsumerState<TerminalWorkspacePage> createState() =>
      _TerminalWorkspacePageState();
}

class _TerminalWorkspacePageState
    extends ConsumerState<TerminalWorkspacePage> {
  final _appState = AppState();

  @override
  void initState() {
    super.initState();
    if (!widget.initialize) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomePanel();
      for (final definition in widget.profile.sessions) {
        _addTerminal(definition);
      }
    });
  }

  void _addTerminal([SessionProfile? definition]) {
    final number = _appState.nextTerminalNumber++;
    final id = definition?.id ?? 'terminal-$number';
    final session = _appState.createSession(id, definition: definition);
    ref.read(dockManagerProvider.notifier).addPanel(
          DockPanel(
            id: id,
            title: definition?.name ?? 'Terminal $number',
            icon: Icons.terminal,
            builder: (_) => TerminalPane(
              key: ValueKey(number),
              session: session,
            ),
          ),
        );
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  void _addWelcomePanel() {
    ref.read(dockManagerProvider.notifier).addPanel(
          DockPanel(
            id: 'welcome',
            title: 'Welcome',
            icon: Icons.waving_hand_outlined,
            closable: false,
            builder: (_) => _WelcomePanel(onPressed: _addTerminal),
          ),
        );
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
          tabPadding: const EdgeInsets.only(
            left: 14,
            top: 0,
            right: 14,
          ),
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
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('New terminal'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xffe7ebf2),
          backgroundColor: const Color(0xff2a303a),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xff4a5361)),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
