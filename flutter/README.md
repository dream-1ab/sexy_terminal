# Sexy Terminal

Sexy Terminal is a Flutter desktop terminal workspace for organizing repeatable project workflows. It combines dockable terminal panels with workspace profiles, so a project can reopen with its familiar terminal layout and commands.

## Features

- Dockable, splittable, and tabbed terminal panels
- Persistent terminal sessions while switching tabs
- Workspace profiles for different projects or workflows
- Named and colorized terminal sessions
- Per-session shell and working directory
- Per-session startup command sequences
- Welcome page for opening and creating profiles
- Profile editor for managing sessions and layout
- Native local PTY support through `flutter_pty`
- Terminal emulation and rendering through `xterm`

## Workspace Profiles

A workspace profile is a named configuration for one project or workflow. It stores the dock layout and the terminal sessions that should be opened when the profile starts.

Each session can define:

- Display name
- Tab color
- Shell executable
- Initial working directory
- Startup commands
- Restart behavior

Example profile:

```text
Profile: Model training

Codex
  directory: ~/projects/model
  startup: codex

Training
  directory: ~/projects/model
  startup: ./scripts/train.sh

TensorBoard
  directory: ~/projects/model
  startup: tensorboard --logdir runs

GPU monitor
  directory: ~/projects/model
  startup: nvtop
```

The saved profile is configuration. Opening it creates live terminal sessions from that configuration. Each live session owns its PTY, terminal buffer, controller, process state, and scrollback.

## Startup Commands

Startup commands are entered into the session's shell after it starts. This supports workflows that require several interactive steps:

```text
ssh gpu-server
cd ~/projects/model
source .venv/bin/activate
tensorboard --logdir runs
```

This uses the normal local PTY and shell, so the application does not need a separate SSH client. SSH login, directory changes, virtual-environment activation, and interactive command-line tools use the same input path as normal typing.

Commands should be treated as shell input. A command that waits for a password, confirmation, or another interactive response can pause the remaining sequence.

## Development

The project uses the Flutter SDK selected by FVM:

```sh
fvm use 3.50.0
cd flutter
fvm flutter pub get
fvm flutter run -d macos
```

Run verification with:

```sh
cd flutter
fvm flutter analyze
fvm flutter test
fvm flutter build macos --debug
```

## Architecture

- `lib/app.dart` contains application setup and theme configuration.
- `lib/app_state.dart` contains application and terminal-session state.
- `lib/ui/pages/` contains the workspace and terminal views.
- `dock_panel` provides docking, splitting, tabbing, and layout management.
- `xterm` provides terminal emulation and rendering.
- `flutter_pty` provides the native local PTY process.

The original Python implementation is preserved in the repository's `python/` directory.
