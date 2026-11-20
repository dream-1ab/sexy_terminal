import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart' as app_provider;

import 'window_app_shell.dart';
import 'app_log.dart';
import 'app_state.dart';
import 'window_navigator.dart';
import 'ui/pages/launcher_page.dart';
import 'ui/pages/terminal_workspace_page.dart';

WindowSpec launcherWindowSpec(AppState appState) => WindowSpec(
  id: 'launcher',
  title: 'Sexy terminal',
  size: const Size(980, 700),
  builder: (context) {
    final navigator = WindowNavigator.of(context);
    return app_provider.ChangeNotifierProvider.value(
      value: appState,
      child: SexyTerminalApp(
        onContextReady: (context) =>
            navigator.registerContext('launcher', context),
        home: LauncherPage(
          onOpenWorkspace: (id) {
            appState.activateWorkspace(id);
            navigator.open(workspaceWindowSpec(appState, id));
          },
        ),
      ),
    );
  },
);

WindowSpec workspaceWindowSpec(AppState appState, String workspaceId) {
  final profile = appState.workspaceById(workspaceId);
  ProviderContainer? riverpodContainer;
  return WindowSpec(
    id: 'workspace:$workspaceId',
    title: profile?.name ?? 'Workspace',
    size: const Size(1200, 800),
    onClosed: () {
      riverpodContainer?.dispose();
      appState.deactivateWorkspace(workspaceId);
    },
    builder: (context) {
      final navigator = WindowNavigator.of(context);
      final container = riverpodContainer ??= ProviderContainer();
      return app_provider.ChangeNotifierProvider.value(
        value: appState,
        child: UncontrolledProviderScope(
          container: container,
          child: app_provider.ListenableProvider<WorkspaceRuntimeState>(
            create: (_) => WorkspaceRuntimeState(
              appState: appState,
              workspaceId: workspaceId,
            ),
            dispose: (_, runtime) {
              appLog(
                AppLogTag.workspace,
                'Scheduling next-frame disposal for workspace runtime '
                '${runtime.workspaceId}.',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appLog(
                  AppLogTag.workspace,
                  'Running scheduled workspace runtime disposal for '
                  '${runtime.workspaceId}.',
                );
                runtime.dispose();
              });
            },
            child: SexyTerminalApp(
              onContextReady: (context) =>
                  navigator.registerContext('workspace:$workspaceId', context),
              home: TerminalWorkspacePage(workspaceId: workspaceId),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> requestApplicationQuit(
  BuildContext context,
  AppState appState,
) async {
  if (appState.activatedWorkspaceIds.isEmpty) {
    await ServicesBinding.instance.exitApplication(AppExitType.required);
    return;
  }
  final confirmed = await showMacosAlertDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => MacosAlertDialog(
      appIcon: const Icon(Icons.terminal, size: 48),
      title: const Text('Quit Sexy terminal?'),
      message: Text(
        '${appState.activatedWorkspaceIds.length} workspace window(s) '
        'are still running.',
      ),
      secondaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Quit'),
      ),
    ),
  );
  if (confirmed == true) {
    await ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}
