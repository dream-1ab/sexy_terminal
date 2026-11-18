import 'package:flutter/material.dart';

import 'ui/pages/profile_home_page.dart';

class SexyTerminalApp extends StatelessWidget {
  const SexyTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sexy terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color.fromRGBO(43, 43, 43, 1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffb8c0cc),
          onPrimary: Color(0xff121314),
          secondary: Color(0xff9ca6b5),
          onSecondary: Color(0xff121314),
          surface: Color(0xff121314),
          onSurface: Color(0xffe7ebf2),
          error: Color(0xffe57373),
          onError: Color(0xff121314),
        ),
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        visualDensity: VisualDensity.compact,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: const RoundedRectangleBorder(),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            backgroundColor: const Color(0xff2a3036),
            foregroundColor: const Color(0xffe7ebf2),
            side: const BorderSide(color: Color(0xff4a5361)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color.fromRGBO(18, 19, 20, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color.fromRGBO(18, 19, 20, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const ProfileHomePage(),
    );
  }
}
