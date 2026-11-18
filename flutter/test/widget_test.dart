import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sexy_terminal/ui/pages/terminal_workspace_page.dart';
import 'package:sexy_terminal/profile_models.dart';

void main() {
  testWidgets('terminal workspace renders', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: TerminalWorkspacePage(
          initialize: false,
          profile: WorkspaceProfile(id: 'test', name: 'Test'),
        ),
      ),
    ));
    expect(find.byType(TerminalWorkspacePage), findsOneWidget);
  });
}
