import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as app_provider;

import 'app_state.dart';
import 'app_windows.dart';
import 'window_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runWidget(
    app_provider.ChangeNotifierProvider.value(
      value: appState,
      child: WindowNavigator(
        defaultWindow: launcherWindowSpec(appState),
        emptyWindowPolicy: EmptyWindowPolicy.quitApplication,
        onQuitRequested: (context) => requestApplicationQuit(context, appState),
      ),
    ),
  );
}
