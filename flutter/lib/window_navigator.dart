// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';

enum EmptyWindowPolicy { relaunchDefault, quitApplication, doNothing }

class WindowSpec {
  const WindowSpec({
    required this.id,
    required this.title,
    required this.builder,
    this.size,
    this.onClosed,
  });

  final String id;
  final String title;
  final Size? size;
  final WidgetBuilder builder;
  final VoidCallback? onClosed;
}

class WindowNavigator extends StatefulWidget {
  const WindowNavigator({
    super.key,
    required this.defaultWindow,
    this.emptyWindowPolicy = EmptyWindowPolicy.relaunchDefault,
    this.onQuitRequested,
  });

  final WindowSpec defaultWindow;
  final EmptyWindowPolicy emptyWindowPolicy;
  final Future<void> Function(BuildContext context)? onQuitRequested;

  static WindowNavigatorController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_WindowNavigatorScope>();
    assert(scope != null, 'No WindowNavigator found in the widget tree.');
    return scope!.controller;
  }

  @override
  State<WindowNavigator> createState() => _WindowNavigatorState();
}

class WindowNavigatorController {
  WindowNavigatorController._(this._state);

  final _WindowNavigatorState _state;

  void open(WindowSpec spec) => _state._open(spec);
  void openOrFocus(WindowSpec spec) => _state._open(spec);
  void openDefault() => _state._open(_state.widget.defaultWindow);
  void focus(String id) => _state._focus(id);
  void close(String id) => _state._close(id);
  void closeCurrent(BuildContext context) =>
      _state._controllerFor(context)?.destroy();
  void minimizeCurrent(BuildContext context) =>
      _state._controllerFor(context)?.setMinimized(true);
  void closeAll({bool quit = true}) => _state._closeAll(quit: quit);
  Future<void> requestQuit(BuildContext context) async {
    final callback = _state.widget.onQuitRequested;
    if (callback != null) await callback(context);
  }

  void registerContext(String id, BuildContext context) {
    _state._entryContexts[id] = context;
  }
}

class _WindowNavigatorState extends State<WindowNavigator> {
  late final WindowNavigatorController controller;
  late final WindowEntry _defaultEntry;
  final _entries = <String, _WindowHandle>{};
  final _entryContexts = <String, BuildContext>{};
  WindowRegistry? _registry;
  var _suppressEmptyPolicy = false;

  @override
  void initState() {
    super.initState();
    controller = WindowNavigatorController._(this);
    _defaultEntry = _createEntry(widget.defaultWindow);
  }

  WindowEntry _createEntry(WindowSpec spec) {
    late final WindowEntry entry;
    final nativeController = WindowController(
      size: spec.size ?? const Size(980, 700),
      title: spec.title,
      delegate: _NavigatorWindowDelegate(
        onDestroyed: () {
          _registry?.unregister(entry);
          _entries.remove(spec.id);
          spec.onClosed?.call();
          _handleEmptyWindows();
        },
      ),
    );
    entry = WindowEntry(
      controller: nativeController,
      builder: (context) {
        _registry ??= WindowRegistry.of(context);
        _entryContexts[spec.id] = context;
        return spec.builder(context);
      },
    );
    _entries[spec.id] = _WindowHandle(spec: spec, entry: entry);
    return entry;
  }

  void _open(WindowSpec spec) {
    final registry = _registry;
    if (registry == null) return;
    final existing = _entries[spec.id];
    if (existing != null && !existing.controller.isDestroyed) {
      existing.controller.activate();
      return;
    }
    final entry = _createEntry(spec);
    registry.register(entry);
    (entry.controller as WindowController).activate();
  }

  void _focus(String id) {
    _entries[id]?.controller.activate();
  }

  void _close(String id) {
    _entries[id]?.controller.destroy();
  }

  void _closeAll({required bool quit}) {
    _suppressEmptyPolicy = true;
    final controllers = _entries.values
        .where((handle) => handle.spec.id != widget.defaultWindow.id)
        .map((handle) => handle.controller)
        .toList();
    for (final controller in controllers) {
      controller.destroy();
    }
    _suppressEmptyPolicy = false;
    if (quit) {
      ServicesBinding.instance.exitApplication(AppExitType.required);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(widget.defaultWindow);
      });
    }
  }

  WindowController? _controllerFor(BuildContext context) {
    final current = WindowScope.of(context);
    for (final handle in _entries.values) {
      if (identical(handle.controller, current)) return handle.controller;
    }
    return null;
  }

  _WindowHandle? get _activeHandle {
    for (final handle in _entries.values) {
      if (!handle.controller.isDestroyed && handle.controller.isActivated) {
        return handle;
      }
    }
    return null;
  }

  void _minimizeActive() => _activeHandle?.controller.setMinimized(true);

  void _closeActive() => _activeHandle?.controller.destroy();

  Future<void> _requestQuitFromMenu() async {
    final context = _entryContexts[_activeHandle?.spec.id];
    if (context == null) {
      await ServicesBinding.instance.exitApplication(AppExitType.required);
      return;
    }
    final callback = widget.onQuitRequested;
    if (callback != null) await callback(context);
  }

  void _handleEmptyWindows() {
    if (_suppressEmptyPolicy || _entries.isNotEmpty) return;
    switch (widget.emptyWindowPolicy) {
      case EmptyWindowPolicy.relaunchDefault:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _open(widget.defaultWindow);
        });
      case EmptyWindowPolicy.quitApplication:
        ServicesBinding.instance.exitApplication(AppExitType.required);
      case EmptyWindowPolicy.doNothing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Sexy terminal',
          menus: [
            PlatformMenuItem(
              label: 'Quit Sexy terminal',
              shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
              onSelected: _requestQuitFromMenu,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
          menus: [
            PlatformMenuItem(
              label: 'New Window',
              shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
              onSelected: controller.openDefault,
            ),
            PlatformMenuItem(
              label: 'Minimize',
              shortcut: SingleActivator(LogicalKeyboardKey.keyM, meta: true),
              onSelected: _minimizeActive,
            ),
            PlatformMenuItem(
              label: 'Close Window',
              shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true),
              onSelected: _closeActive,
            ),
          ],
        ),
      ],
      child: _WindowNavigatorScope(
        controller: controller,
        child: WindowManager(initialWindows: [_defaultEntry]),
      ),
    );
  }

  @override
  void dispose() {
    _suppressEmptyPolicy = true;
    for (final handle in List<_WindowHandle>.from(_entries.values)) {
      if (!handle.controller.isDestroyed) handle.controller.destroy();
    }
    super.dispose();
  }
}

class _WindowHandle {
  const _WindowHandle({required this.spec, required this.entry});

  final WindowSpec spec;
  final WindowEntry entry;

  WindowController get controller => entry.controller as WindowController;
}

class _WindowNavigatorScope extends InheritedWidget {
  const _WindowNavigatorScope({required this.controller, required super.child});

  final WindowNavigatorController controller;

  @override
  bool updateShouldNotify(_WindowNavigatorScope oldWidget) =>
      controller != oldWidget.controller;
}

class _NavigatorWindowDelegate with WindowControllerDelegate {
  _NavigatorWindowDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}
