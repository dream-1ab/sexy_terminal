from PySide6.QtWidgets import QApplication


def apply_theme(app: QApplication) -> None:
    app.setStyle("Fusion")
    app.setStyleSheet("""
        QMainWindow, QWidget { background: #303030; color: #cccccc; }
        QToolBar { background: #272727; border: 0; spacing: 4px; padding: 3px; }
        QToolButton { color: #cccccc; background: transparent; border: 0; padding: 4px 8px; }
        QToolButton:hover { background: #3b3b3b; }
        QDockWidget { border: 1px solid #202020; }
        QDockWidget::title { background: #272727; color: #cccccc; padding: 6px 8px; border-bottom: 1px solid #1d1d1d; }
        QTabBar { background: #272727; qproperty-drawBase: 0; }
        QTabBar::tab { background: #303030; color: #a9a9a9; border: 0; border-right: 1px solid #202020; padding: 5px 10px; min-width: 82px; }
        QTabBar::tab:hover { background: #383838; color: #e0e0e0; }
        QTabBar::tab:selected { background: #404040; color: #f0f0f0; padding-top: 5px; }
    """)
