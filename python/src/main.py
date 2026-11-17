import sys

from PySide6.QtWidgets import QApplication

from main_window import MainWindow
from theme import apply_theme
from workspace_dialog import WorkspaceDialog
from workspace_manager import WorkspaceManager
from settings_manager import SettingsManager


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("ReMinal")
    app.setApplicationDisplayName("ReMinal")
    apply_theme(app)
    manager = WorkspaceManager()
    settings = SettingsManager()
    name = WorkspaceDialog.choose(manager)
    workspace = manager.load(name) if name else None
    window = MainWindow(manager, workspace, settings)
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
