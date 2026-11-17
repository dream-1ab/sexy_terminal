# ReMinal

A small native Qt terminal workspace: a `QMainWindow` whose docks each hold a
terminal, tabbed together, with a "New Terminal" toolbar action. A dock can be
dragged out to float on its own, dragged back beside another one to split, or
closed; a shell exiting closes its own dock.

## Running

```sh
python3 -m uv run ./src/main.py
```

## Terminal backend

Parsing, rendering, scrollback and selection come from
[anytermqt](https://github.com/scottpeterman/anytermqt), a C++ Qt widget
exposed to PySide6 through the stable API. ReMinal supplies only the workspace
chrome and the PTY wiring (`PtySession`): bytes in via `feed()`, bytes out via
`dataReady()` -- which also carries the emulator's replies to terminal queries,
the thing shells such as fish wait on -- and grid size via `resized`.

`dataReady` is connected before the first byte arrives, and the reply path
matters as much as the keystroke path: a terminal that swallows Device
Attribute requests makes fish pause for ten seconds and disable features.

Two constraints come with the dependency:

* **PySide6 is pinned to 6.10.3.** anytermqt links PySide6's C++ ABI
  (`libpyside6.abi3.6.10.dylib`), so any other PySide6 fails at `import` with
  a `Library not loaded` error. Keep the pin in step with the wheel.
* **The wheel is vendored in `vendor/`** because anytermqt is not on PyPI. The
  copy committed here is `cp39-abi3-macosx_26_0_arm64` (Apple silicon); other
  platforms need a wheel built from source against the same Qt.

## Licence

anytermqt is GPL-3.0, and linking it puts ReMinal under GPL-3.0 too if it is
ever distributed.
