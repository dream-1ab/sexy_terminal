import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sexy_terminal/ui/components/window_file_drop.dart';

void main() {
  testWidgets('routes drops to the hit pane in the originating view', (
    tester,
  ) async {
    const channel = MethodChannel('reminal/window_file_drop');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });

    final left = <String>[];
    final right = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            WindowFileDrop(
              onDrop: left.addAll,
              child: const SizedBox(width: 100, height: 100),
            ),
            WindowFileDrop(
              onDrop: right.addAll,
              child: const SizedBox(width: 100, height: 100),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final viewId = tester.view.viewId;
    expect(calls.where((call) => call.method == 'attach').length, 1);

    Future<void> drop(int id, double x, double y) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('drop', {
            'viewId': id,
            'x': x,
            'y': y,
            'paths': ['/tmp/example file'],
          }),
        ),
        (_) {},
      );
    }

    final rightCenter = tester.getCenter(find.byType(WindowFileDrop).at(1));
    await drop(viewId + 1000, rightCenter.dx, rightCenter.dy);
    expect(left, isEmpty);
    expect(right, isEmpty);
    await drop(viewId, rightCenter.dx, rightCenter.dy);
    expect(left, isEmpty);
    expect(right, ['/tmp/example file']);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls.where((call) => call.method == 'detach').length, 1);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
