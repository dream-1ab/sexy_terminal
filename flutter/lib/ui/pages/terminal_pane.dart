import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:xterm/xterm.dart';

import 'dart:io';

import '../../app_state.dart';
import '../../terminal_appearance.dart';

class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key, required this.session});

  final TerminalSession session;

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  String _quotePath(String path) {
    if (Platform.isWindows) {
      return '"${path.replaceAll('"', '\\"')}"';
    }
    return "'${path.replaceAll("'", "'\\''")}'";
  }

  void _dropFiles(DropDoneDetails details) {
    final paths = details.files.map((file) => _quotePath(file.path)).join(' ');
    if (paths.isEmpty) return;
    widget.session.writeText(paths);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return DropTarget(
      onDragDone: _dropFiles,
      child: ValueListenableBuilder<TerminalAppearanceProfile>(
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
                hardwareKeyboardOnly: true,
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
      ),
    );
  }
}
