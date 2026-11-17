import 'dart:convert';
import 'dart:io';

import 'package:dock_panel/dock_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

void main() => runApp(const ProviderScope(child: SexyTerminalApp()));

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
      home: const TerminalWorkspace(),
    );
  }
}

class TerminalWorkspace extends ConsumerStatefulWidget {
  const TerminalWorkspace({super.key});

  @override
  ConsumerState<TerminalWorkspace> createState() => _TerminalWorkspaceState();
}

class _TerminalWorkspaceState extends ConsumerState<TerminalWorkspace> {
  var _nextTerminal = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _addTerminal());
  }

  void _addTerminal() {
    final number = _nextTerminal++;
    ref.read(dockManagerProvider.notifier).addPanel(
          DockPanel(
            id: 'terminal-$number',
            title: 'Terminal $number',
            icon: Icons.terminal,
            builder: (_) => TerminalPane(key: ValueKey(number)),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sexy terminal'),
        backgroundColor: const Color(0xff171a21),
        actions: [
          IconButton(
            tooltip: 'New terminal',
            onPressed: _addTerminal,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: DockTheme(
        data: DockThemeData(
          backgroundColor: const Color(0xff111318),
          tabBarColor: const Color(0xff1b1f27),
          activeTabColor: const Color(0xff242a34),
          dividerColor: const Color(0xff343b48),
          tabTextColor: const Color(0xffb8c0cc),
          activeTabTextColor: Colors.white,
          dividerThickness: 4,
          tabHeight: 34,
        ),
        child: const DockArea(),
      ),
    );
  }
}

class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key});

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  final terminal = Terminal(maxLines: 10000);
  final controller = TerminalController();
  Pty? _pty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startPty();
    });
  }

  void _startPty() {
    final shell = Platform.environment['SHELL'] ?? (Platform.isWindows ? 'cmd.exe' : 'bash');
    final pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    _pty = pty;
    pty.output.cast<List<int>>().transform(utf8.decoder).listen(terminal.write);
    pty.exitCode.then((code) {
      if (mounted) terminal.write('\r\n[process exited: $code]\r\n');
    });
    terminal.onOutput = (data) => pty.write(utf8.encode(data));
    terminal.onResize = (width, height, _, __) => pty.resize(height, width);
  }

  @override
  void dispose() {
    _pty?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff0d0f12),
      child: TerminalView(
        terminal,
        controller: controller,
        autofocus: true,
        backgroundOpacity: 1,
        onSecondaryTapDown: (details, offset) async {
          final selection = controller.selection;
          if (selection != null) {
            final text = terminal.buffer.getText(selection);
            controller.clearSelection();
            await Clipboard.setData(ClipboardData(text: text));
          } else {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null) terminal.paste(data!.text!);
          }
        },
      ),
    );
  }
}
