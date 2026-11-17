from __future__ import annotations

import os
import re
import shlex
import sys
from urllib.parse import unquote, urlparse

import anytermqt
from PySide6.QtCore import Qt, Slot
from PySide6.QtGui import QColor, QFont
from PySide6.QtWidgets import QApplication, QAbstractScrollArea, QDockWidget, QWidget


class TerminalWidget(anytermqt.TerminalWidget):
    def keyPressEvent(self, event) -> None:
        # On macOS Qt maps physical Command to ControlModifier; physical
        # Control arrives as MetaModifier and must remain a shell interrupt.
        if sys.platform == "darwin":
            copy_key = event.key() == Qt.Key.Key_C and event.modifiers() == Qt.KeyboardModifier.ControlModifier
            paste_key = event.key() == Qt.Key.Key_V and event.modifiers() == Qt.KeyboardModifier.ControlModifier
        else:
            copy_key = event.key() == Qt.Key.Key_C and event.modifiers() == (Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier)
            paste_key = event.key() == Qt.Key.Key_V and event.modifiers() == (Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier)
        if copy_key:
            if self.hasSelection():
                self.copySelection()
            event.accept()
            return
        if paste_key:
            self.paste(QApplication.clipboard().text())
            event.accept()
            return
        if event.key() == Qt.Key.Key_Tab and not event.modifiers():
            self.send("\t")
            event.accept()
            return
        super().keyPressEvent(event)

    def focusNextPrevChild(self, next_child: bool) -> bool:
        self.send("\t" if next_child else "\x1b[Z")
        return True


class TerminalDock(QDockWidget):
    def __init__(self, owner, number: int, cwd: str | None = None) -> None:
        super().__init__(f"Terminal {number}", owner)
        self.owner = owner
        self.number = number
        self.cwd = cwd if cwd and os.path.isdir(cwd) else os.path.expanduser("~")
        self.setObjectName(f"terminal_{number}")
        self.setAllowedAreas(Qt.DockWidgetArea.AllDockWidgetAreas)
        self.setFeatures(QDockWidget.DockWidgetFeature.DockWidgetMovable | QDockWidget.DockWidgetFeature.DockWidgetFloatable | QDockWidget.DockWidgetFeature.DockWidgetClosable)
        self._hidden_title_bar = QWidget()
        self.setTitleBarWidget(self._hidden_title_bar)
        self.terminal = TerminalWidget()
        self.terminal.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
        self.terminal.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        self.terminal.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.session = anytermqt.PtySession.create(self.terminal)
        self.setWidget(self.terminal)
        self.session.dataReceived.connect(self.terminal.feed)
        self.terminal.dataReady.connect(self.session.write)
        self.terminal.resized.connect(self.session.resize)
        self.session.finished.connect(self._on_finished)
        self.topLevelChanged.connect(self._update_title)
        self._started = False
        self._closing = False
        self._cwd_output = b""
        self.session.dataReceived.disconnect(self.terminal.feed)
        self.session.dataReceived.connect(self._handle_output)

    def _handle_output(self, data: bytes) -> None:
        data = bytes(data)
        self._cwd_output += data
        markers = (
            re.compile(rb"\x1b\]777;reminal-cwd=([^\x07]*)\x07"),
            re.compile(rb"\x1b\]7;([^\x07]*)\x07"),
        )
        for marker in markers:
            for match in marker.finditer(self._cwd_output):
                value = unquote(match.group(1).decode(errors="replace"))
                path = urlparse(value).path if value.startswith(("file://", "file:")) else value
                if path and os.path.isdir(path):
                    self.cwd = path
            self._cwd_output = marker.sub(b"", self._cwd_output)
            data = marker.sub(b"", data)
        self._cwd_output = self._cwd_output[-4096:]
        self.terminal.feed(data)

    def start(self) -> None:
        if self._started:
            return
        self._started = True
        shell = os.environ.get("SHELL", "/bin/zsh")
        command = f"cd -- {shlex.quote(self.cwd)} && exec {shlex.quote(shell)} -l"
        self.session.start("/bin/sh", ["-lc", command], [], self.terminal.columns(), self.terminal.terminalRows())
        self.terminal.setFocus()

    def apply_settings(self, settings) -> None:
        self.terminal.setTerminalFont(QFont(settings.values["font_family"], int(settings.values["font_size"])))
        palette = self.terminal.terminalPalette()
        theme = settings.theme
        palette.set_background(QColor(theme["background"]))
        palette.set_foreground(QColor(theme["foreground"]))
        palette.set_cursor(QColor(theme["cursor"]))
        self.terminal.setTerminalPalette(palette)

    def request_cwd(self) -> None:
        self.terminal.send("printf '\\033]777;reminal-cwd=%s\\007' \"$PWD\"\n")

    @Slot()
    def _update_title(self) -> None:
        self.setTitleBarWidget(None if self.isFloating() else self._hidden_title_bar)
        base = self.windowTitle().replace(" (Floating)", "")
        self.setWindowTitle(base + (" (Floating)" if self.isFloating() else ""))

    @Slot()
    def _on_finished(self) -> None:
        if not self._closing:
            self.close()

    def closeEvent(self, event) -> None:
        self._closing = True
        self.session.terminate()
        super().closeEvent(event)
