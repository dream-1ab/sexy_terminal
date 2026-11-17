from __future__ import annotations

import base64
import json
from pathlib import Path

from workspace_model import TerminalState, Workspace


class WorkspaceManager:
    def __init__(self) -> None:
        self.directory = Path.home() / "Library" / "Application Support" / "ReMinal" / "workspaces"
        self.directory.mkdir(parents=True, exist_ok=True)

    def list(self) -> list[str]:
        return sorted(p.stem for p in self.directory.glob("*.json"))

    def load(self, name: str) -> Workspace:
        data = json.loads((self.directory / f"{name}.json").read_text())
        return Workspace(name=name, terminals=[TerminalState(**item) for item in data.get("terminals", [])], geometry=data.get("geometry", ""), state=data.get("state", ""))

    def save(self, workspace: Workspace) -> None:
        payload = {"terminals": [vars(item) for item in workspace.terminals], "geometry": workspace.geometry, "state": workspace.state}
        (self.directory / f"{workspace.name}.json").write_text(json.dumps(payload, indent=2))

    def delete(self, name: str) -> None:
        (self.directory / f"{name}.json").unlink(missing_ok=True)
