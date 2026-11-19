import 'package:flutter/material.dart';

import 'app_state.dart';
import 'app_windows.dart';
import 'window_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runWidget(
    WindowNavigator(
      defaultWindow: launcherWindowSpec(appState),
      emptyWindowPolicy: EmptyWindowPolicy.quitApplication,
      onQuitRequested: (context) => requestApplicationQuit(context, appState),
    ),
  );
}
