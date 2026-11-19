import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class SexyTerminalApp extends StatelessWidget {
  const SexyTerminalApp({super.key, this.home, this.onContextReady});

  final Widget? home;
  final ValueChanged<BuildContext>? onContextReady;

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Sexy terminal',
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.dark().copyWith(
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        dividerColor: const Color.fromRGBO(43, 43, 43, 1),
        primaryColor: const Color.fromARGB(255, 79, 161, 255),
      ),
      darkTheme: MacosThemeData.dark().copyWith(
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        dividerColor: const Color.fromRGBO(43, 43, 43, 1),
        primaryColor: const Color.fromARGB(255, 75, 159, 255),
      ),
      home: Builder(
        builder: (context) {
          onContextReady?.call(context);
          return home ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
