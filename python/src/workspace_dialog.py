from __future__ import annotations

from PySide6.QtWidgets import QDialog, QDialogButtonBox, QInputDialog, QListWidget, QVBoxLayout


class WorkspaceDialog(QDialog):
    def __init__(self, manager, parent=None) -> None:
        super().__init__(parent)
        self.manager = manager
        self.setWindowTitle("Choose Workspace")
        self.list_widget = QListWidget()
        self.list_widget.addItems(manager.list())
        self.list_widget.itemDoubleClicked.connect(lambda _: self.accept())
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout = QVBoxLayout(self)
        layout.addWidget(self.list_widget)
        layout.addWidget(buttons)

    @property
    def selected(self) -> str | None:
        item = self.list_widget.currentItem()
        return item.text() if item else None

    @staticmethod
    def choose(manager, parent=None) -> str | None:
        names = manager.list()
        if not names:
            name, ok = QInputDialog.getText(parent, "New Workspace", "Workspace name:")
            return name.strip() if ok and name.strip() else None
        dialog = WorkspaceDialog(manager, parent)
        return dialog.selected if dialog.exec() == QDialog.DialogCode.Accepted else None
