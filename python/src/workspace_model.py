from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class TerminalState:
    number: int
    cwd: str


@dataclass
class Workspace:
    name: str
    terminals: list[TerminalState] = field(default_factory=list)
    geometry: str = ""
    state: str = ""
