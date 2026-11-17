from __future__ import annotations

import json
from pathlib import Path


THEMES = {
    "ReMinal Dark": {"background": "#101216", "foreground": "#d7dae0", "cursor": "#d7dae0"},
    "Tokyo Night": {"background": "#1a1b26", "foreground": "#c0caf5", "cursor": "#7aa2f7"},
    "Nord": {"background": "#2e3440", "foreground": "#d8dee9", "cursor": "#88c0d0"},
    "Solarized Dark": {"background": "#002b36", "foreground": "#839496", "cursor": "#b58900"},
}


class SettingsManager:
    def __init__(self) -> None:
        self.path = Path.home() / "Library" / "Application Support" / "ReMinal" / "settings.json"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.values = {"font_family": "Menlo", "font_size": 12, "theme": "ReMinal Dark"}
        if self.path.exists():
            try:
                self.values.update(json.loads(self.path.read_text()))
            except (OSError, ValueError):
                pass

    def save(self) -> None:
        self.path.write_text(json.dumps(self.values, indent=2))

    @property
    def theme(self) -> dict[str, str]:
        return THEMES.get(self.values["theme"], THEMES["ReMinal Dark"])
