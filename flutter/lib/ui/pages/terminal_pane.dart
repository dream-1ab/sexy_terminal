import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../app_state.dart';
import '../../terminal_appearance.dart';

class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key, required this.session});

  final TerminalSession session;

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return ValueListenableBuilder<TerminalAppearanceProfile>(
      valueListenable: session.appearance,
      builder: (context, appearance, child) => ColoredBox(
        color: appearance.theme.background,
        child: ClipRect(
          child: Padding(
            padding: EdgeInsetsGeometry.all(8),
            child: TerminalView(
              session.terminal,
              controller: session.controller,
              theme: appearance.theme,
              textStyle: appearance.textStyle,
              autofocus: true,
              backgroundOpacity: 1,
              onSecondaryTapDown: (details, offset) async {
                final selection = session.controller.selection;
                if (selection != null) {
                  final text = session.terminal.buffer.getText(selection);
                  session.controller.clearSelection();
                  await Clipboard.setData(ClipboardData(text: text));
                } else {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) session.terminal.paste(data!.text!);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
