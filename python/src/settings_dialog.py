from __future__ import annotations

from PySide6.QtGui import QFontDatabase
from PySide6.QtWidgets import QComboBox, QDialog, QDialogButtonBox, QFormLayout, QSpinBox

from settings_manager import THEMES


class SettingsDialog(QDialog):
    def __init__(self, settings, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Settings")
        self.fonts = QComboBox()
        self.fonts.addItems(sorted(QFontDatabase.families()))
        self.fonts.setCurrentText(settings.values["font_family"])
        self.size = QSpinBox(); self.size.setRange(8, 32); self.size.setValue(int(settings.values["font_size"]))
        self.themes = QComboBox(); self.themes.addItems(THEMES); self.themes.setCurrentText(settings.values["theme"])
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept); buttons.rejected.connect(self.reject)
        form = QFormLayout(self); form.addRow("Font", self.fonts); form.addRow("Size", self.size); form.addRow("Theme", self.themes); form.addRow(buttons)

    def values(self) -> dict:
        return {"font_family": self.fonts.currentText(), "font_size": self.size.value(), "theme": self.themes.currentText()}
