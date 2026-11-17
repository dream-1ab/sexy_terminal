import 'package:flutter/material.dart';

import 'ui/pages/terminal_workspace_page.dart';

class SexyTerminalApp extends StatelessWidget {
  const SexyTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sexy terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff111318),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6ee7b7),
          brightness: Brightness.dark,
        ),
      ),
      home: const TerminalWorkspacePage(),
    );
  }
}
