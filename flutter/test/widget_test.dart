import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sexy_terminal/main.dart';

void main() {
  testWidgets('terminal workspace renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SexyTerminalApp()));
    expect(find.text('Sexy terminal'), findsOneWidget);
  });
}
