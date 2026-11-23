import 'dart:async';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Receives filesystem drops only from the Flutter view containing [child].
class WindowFileDrop extends StatefulWidget {
  const WindowFileDrop({super.key, required this.onDrop, required this.child});

  final ValueChanged<List<String>> onDrop;
  final Widget child;

  @override
  State<WindowFileDrop> createState() => _WindowFileDropState();
}

class _WindowFileDropState extends State<WindowFileDrop> {
  int? _viewId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewId = View.of(context).viewId;
    if (_viewId == viewId) return;
    if (_viewId case final oldId?) {
      _WindowDropCoordinator.instance.remove(oldId);
    }
    _viewId = viewId;
    _WindowDropCoordinator.instance.add(viewId);
  }

  @override
  void dispose() {
    if (_viewId case final viewId?) {
      _WindowDropCoordinator.instance.remove(viewId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MetaData(
    metaData: this,
    behavior: HitTestBehavior.translucent,
    child: widget.child,
  );
}

class _WindowDropCoordinator {
  _WindowDropCoordinator() {
    _channel.setMethodCallHandler(_handle);
  }

  static final instance = _WindowDropCoordinator();
  static const _channel = MethodChannel('reminal/window_file_drop');
  final _counts = <int, int>{};

  void add(int viewId) {
    final count = _counts[viewId] ?? 0;
    _counts[viewId] = count + 1;
    if (count == 0) {
      unawaited(_invoke('attach', viewId));
    }
  }

  void remove(int viewId) {
    final count = _counts[viewId] ?? 0;
    if (count <= 1) {
      _counts.remove(viewId);
      unawaited(_invoke('detach', viewId));
    } else {
      _counts[viewId] = count - 1;
    }
  }

  Future<void> _invoke(String method, int viewId) async {
    try {
      await _channel.invokeMethod<void>(method, viewId);
    } on PlatformException catch (error) {
      debugPrint('Window file drop $method failed for view $viewId: $error');
    } on MissingPluginException catch (error) {
      debugPrint('Window file drop is unavailable: $error');
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'drop') return;
    final args = Map<Object?, Object?>.from(call.arguments as Map);
    final viewId = args['viewId'] as int;
    if (!_counts.containsKey(viewId)) return;
    final paths = (args['paths'] as List).cast<String>();
    if (paths.isEmpty) return;
    var position = Offset(
      (args['x'] as num).toDouble(),
      (args['y'] as num).toDouble(),
    );
    if (Platform.isWindows) {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      final view = views.where((view) => view.viewId == viewId).firstOrNull;
      if (view == null) return;
      position /= view.devicePixelRatio;
    }
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, position, viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData && target.metaData is _WindowFileDropState) {
        final state = target.metaData as _WindowFileDropState;
        if (state.mounted && state._viewId == viewId) {
          state.widget.onDrop(paths);
          return;
        }
      }
    }
  }
}
