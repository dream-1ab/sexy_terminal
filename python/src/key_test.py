"""Small Qt modifier diagnostic window for macOS keyboard testing."""

from __future__ import annotations

import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QLabel, QVBoxLayout, QWidget


class KeyWindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("ReMinal Key Test")
        self.resize(720, 260)
        self.label = QLabel("Press Command+C and Control+C here")
        self.label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.label.setWordWrap(True)
        layout = QVBoxLayout(self)
        layout.addWidget(self.label)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)

    def keyPressEvent(self, event) -> None:
        self.label.setText(
            "key: {key}\n"
            "text: {text!r}\n"
            "Qt modifiers: {mods} (value {mod_value})\n"
            "native modifiers: {native_mods}\n"
            "native scan code: {scan}\n\n"
            "Press another key to compare.".format(
                key=event.key(),
                text=event.text(),
                mods=event.modifiers(),
                mod_value=event.modifiers().value,
                native_mods=event.nativeModifiers(),
                scan=event.nativeScanCode(),
            )
        )
        event.accept()


def main() -> int:
    app = QApplication(sys.argv)
    window = KeyWindow()
    window.show()
    window.activateWindow()
    window.setFocus()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
