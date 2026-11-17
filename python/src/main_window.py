from __future__ import annotations

import base64
import os
import sys

from PySide6.QtCore import QCoreApplication, QEvent, QTimer, Qt, Slot
from PySide6.QtGui import QAction
from PySide6.QtWidgets import QApplication, QInputDialog, QMainWindow, QMenu, QTabBar, QTabWidget, QToolButton

from terminal_dock import TerminalDock
from workspace_dialog import WorkspaceDialog
from workspace_manager import WorkspaceManager
from workspace_model import TerminalState, Workspace
from settings_dialog import SettingsDialog


class MainWindow(QMainWindow):
    def __init__(self, manager: WorkspaceManager, workspace: Workspace | None = None, settings=None) -> None:
        super().__init__()
        self.manager = manager
        self.settings = settings
        self.workspace_name = workspace.name if workspace else "Default"
        self._workspace_deleted = False
        self._next_number = 1
        self.setWindowTitle("ReMinal")
        self.resize(1100, 700)
        self.setDockNestingEnabled(True)
        self.setTabPosition(Qt.DockWidgetArea.AllDockWidgetAreas, QTabWidget.TabPosition.North)
        self.setDockOptions(QMainWindow.DockOption.AllowNestedDocks | QMainWindow.DockOption.AllowTabbedDocks | QMainWindow.DockOption.AnimatedDocks | QMainWindow.DockOption.GroupedDragging)
        self._make_menu()
        states = workspace.terminals if workspace else [TerminalState(1, os.getcwd())]
        for state in states:
            self.new_terminal(state.cwd, state.number, tabify=bool(self.findChildren(TerminalDock)))
        if workspace and workspace.geometry and workspace.state:
            self.restoreGeometry(base64.b64decode(workspace.geometry))
            self.restoreState(base64.b64decode(workspace.state))
        QTimer.singleShot(0, self._configure_tab_bars)

    def _make_menu(self) -> None:
        edit_menu = self.menuBar().addMenu("Edit")
        copy_action = QAction("Copy", self)
        copy_action.triggered.connect(self.copy_selection)
        edit_menu.addAction(copy_action)
        paste_action = QAction("Paste", self)
        paste_action.triggered.connect(self.paste_clipboard)
        edit_menu.addAction(paste_action)
        menu = self.menuBar().addMenu("Workspace")
        for label, handler in (("Save", self.save_workspace), ("Save As...", self.save_as), ("Open...", self.open_workspace), ("New Workspace Window...", self.new_workspace_window), ("Delete...", self.delete_workspace)):
            action = QAction(label, self); action.triggered.connect(handler); menu.addAction(action)
        toolbar = self.addToolBar("Workspace"); toolbar.setObjectName("workspace_toolbar"); toolbar.setMovable(False)
        action = QAction("New Terminal", self); action.setShortcut("Ctrl+Shift+T"); action.triggered.connect(self.new_terminal); toolbar.addAction(action)
        settings_menu = self.menuBar().addMenu("Settings")
        settings_action = QAction("Terminal Settings...", self); settings_action.triggered.connect(self.edit_settings); settings_menu.addAction(settings_action)

    @Slot()
    def new_terminal(self, cwd: str | None = None, number: int | None = None, tabify: bool = True) -> None:
        active = self._active_terminal_dock()
        if cwd is None and active is not None:
            cwd = active.cwd
        number = number or self._next_number
        self._next_number = max(self._next_number, number + 1)
        dock = TerminalDock(self, number, cwd or os.getcwd())
        if self.settings:
            dock.apply_settings(self.settings)
        self.addDockWidget(Qt.DockWidgetArea.LeftDockWidgetArea, dock)
        if tabify and active and not active.isFloating(): self.tabifyDockWidget(active, dock)
        dock.raise_(); dock.start(); QTimer.singleShot(0, self._configure_tab_bars)

    def _active_terminal_dock(self) -> TerminalDock | None:
        widget = QApplication.focusWidget()
        while widget:
            if isinstance(widget, TerminalDock): return widget
            widget = widget.parentWidget()
        return None

    @Slot()
    def copy_selection(self) -> None:
        dock = self._active_terminal_dock()
        if dock is not None:
            if dock.terminal.hasSelection():
                dock.terminal.copySelection()
            dock.terminal.setFocus()

    @Slot()
    def paste_clipboard(self) -> None:
        dock = self._active_terminal_dock()
        if dock is not None:
            dock.terminal.paste(QApplication.clipboard().text())
            dock.terminal.setFocus()

    @Slot()
    def edit_settings(self) -> None:
        dialog = SettingsDialog(self.settings, self)
        if dialog.exec() == dialog.DialogCode.Accepted:
            self.settings.values.update(dialog.values())
            self.settings.save()
            for dock in self.findChildren(TerminalDock):
                dock.apply_settings(self.settings)

    def _configure_tab_bars(self) -> None:
        for bar in self.findChildren(QTabBar):
            if bar.property("reminal-close-enabled"): continue
            bar.setTabsClosable(True); bar.setProperty("reminal-close-enabled", True); bar.tabCloseRequested.connect(self._close_tab)
            for index in range(bar.count()):
                button = QToolButton(bar); button.setText("×"); button.setToolTip("Close terminal"); button.setAutoRaise(True); button.setFixedSize(18, 18)
                button.setStyleSheet("QToolButton { color: #999; background: transparent; border: 0; font-size: 15px; padding: 0; } QToolButton:hover { color: #eee; background: #555; border-radius: 3px; }")
                button.clicked.connect(lambda _=False, i=index, b=bar: b.tabCloseRequested.emit(i)); bar.setTabButton(index, QTabBar.ButtonPosition.RightSide, button)

    @Slot(int)
    def _close_tab(self, index: int) -> None:
        bar = self.sender(); title = bar.tabText(index) if isinstance(bar, QTabBar) else ""
        for dock in self.findChildren(TerminalDock):
            if dock.windowTitle().replace(" (Floating)", "") == title: dock.close(); return

    def current_workspace(self) -> Workspace:
        terminals = [TerminalState(d.number, d.cwd) for d in self.findChildren(TerminalDock)]
        return Workspace(self.workspace_name, terminals, base64.b64encode(bytes(self.saveGeometry())).decode(), base64.b64encode(bytes(self.saveState())).decode())

    @Slot()
    def save_workspace(self) -> None:
        for dock in self.findChildren(TerminalDock):
            dock.request_cwd()
        # OSC 7 is emitted by fish after directory changes; save that latest
        # known value immediately so closing the window cannot skip the save.
        self._save_workspace_now()
        QTimer.singleShot(250, self._save_workspace_now)

    def _save_workspace_now(self) -> None:
        if not self._workspace_deleted:
            self.manager.save(self.current_workspace())

    @Slot()
    def save_as(self) -> None:
        name, ok = QInputDialog.getText(self, "Save Workspace", "Workspace name:", text=self.workspace_name)
        if ok and name.strip(): self.workspace_name = name.strip(); self.save_workspace()

    @Slot()
    def open_workspace(self) -> None:
        self.save_workspace()
        name = WorkspaceDialog.choose(self.manager, self)
        if name:
            self._open_workspace_window(name)

    @Slot()
    def new_workspace_window(self) -> None:
        name = WorkspaceDialog.choose(self.manager, self)
        if not name:
            return
        self._open_workspace_window(name)

    def _open_workspace_window(self, name: str) -> None:
        windows = QApplication.instance().property("reminal_windows") or []
        for window in windows:
            if window.workspace_name == name and not window._workspace_deleted:
                window.raise_()
                window.activateWindow()
                return
        window = MainWindow(self.manager, self.manager.load(name))
        windows.append(window)
        QApplication.instance().setProperty("reminal_windows", windows)
        window.show()

    @Slot()
    def delete_workspace(self) -> None:
        name = WorkspaceDialog.choose(self.manager, self)
        if not name:
            return
        self.manager.delete(name)
        windows = QApplication.instance().property("reminal_windows") or []
        for window in windows:
            if window.workspace_name == name:
                window._workspace_deleted = True
                window.close()

    def _replace_workspace(self, workspace: Workspace) -> None:
        old_docks = self.findChildren(TerminalDock)
        for dock in old_docks:
            self.removeDockWidget(dock)
            dock.close()
            dock.setParent(None)
            dock.deleteLater()
        QCoreApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)
        QApplication.processEvents()
        self.workspace_name = workspace.name; self._next_number = 1
        for state in workspace.terminals: self.new_terminal(state.cwd, state.number, tabify=bool(self.findChildren(TerminalDock)))
        if workspace.geometry and workspace.state: self.restoreGeometry(base64.b64decode(workspace.geometry)); self.restoreState(base64.b64decode(workspace.state))

    def closeEvent(self, event) -> None:
        if not self._workspace_deleted:
            self.save_workspace()
        for dock in self.findChildren(TerminalDock): dock.session.terminate()
        app = QApplication.instance()
        windows = app.property("reminal_windows") or []
        app.setProperty("reminal_windows", [window for window in windows if window is not self])
        super().closeEvent(event)
