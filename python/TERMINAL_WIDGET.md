# Terminal Widget Usage

ReMinal uses `anytermqt` for terminal emulation and `PtySession` for the local shell process.

```python
import anytermqt

terminal = anytermqt.TerminalWidget()
session = anytermqt.PtySession.create(terminal)

session.dataReceived.connect(terminal.feed)
terminal.dataReady.connect(session.write)
terminal.resized.connect(session.resize)

session.start(
    "/bin/zsh",
    ["-l"],
    [],
    terminal.columns(),
    terminal.terminalRows(),
)
```

`dataReceived` sends shell output to the widget. `dataReady` sends keyboard input and terminal replies back to the session. The `resized` signal keeps the PTY dimensions synchronized with the widget.

Keep the PySide6 version matched to the `anytermqt` wheel. The current wheel requires PySide6 6.10.3.
