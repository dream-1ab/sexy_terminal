import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../app_state.dart';

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
    return ColoredBox(
      color: const Color(0xff0d0f12),
      child: TerminalView(
        session.terminal,
        controller: session.controller,
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
    );
  }
}
