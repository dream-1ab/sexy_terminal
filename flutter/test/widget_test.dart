import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as app_provider;
import 'package:sexy_terminal/ui/pages/terminal_workspace_page.dart';
import 'package:sexy_terminal/profile_models.dart';
import 'package:sexy_terminal/app_state.dart';

void main() {
  testWidgets('terminal workspace renders', (tester) async {
    final appState = AppState();
    appState.profiles = [WorkspaceProfile(id: 'test', name: 'Test')];
    await tester.pumpWidget(
      app_provider.ChangeNotifierProvider.value(
        value: appState,
        child: ProviderScope(
          child: MaterialApp(
            home: app_provider.ChangeNotifierProvider(
              create: (_) => WorkspaceRuntimeState(
                appState: appState,
                workspaceId: 'test',
              ),
              child: const TerminalWorkspacePage(
                initialize: false,
                workspaceId: 'test',
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(TerminalWorkspacePage), findsOneWidget);
  });
}
