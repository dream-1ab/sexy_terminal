import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sexy_terminal/ui/pages/terminal_workspace_page.dart';

void main() {
  testWidgets('terminal workspace renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: TerminalWorkspacePage(initialize: false),
      ),
    ));
    expect(find.byType(TerminalWorkspacePage), findsOneWidget);
  });
}
