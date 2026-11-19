import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'theme_presets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemePresetStore.instance.initialize();
  runApp(const ProviderScope(child: SexyTerminalApp()));
}
