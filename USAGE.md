# Usage

## Workspace profiles

A workspace profile is a named configuration for one project or workflow. It stores the dock layout and the terminal sessions that should be opened when the profile starts.

Each session can define:

- Display name
- Tab color
- Shell executable
- Initial working directory
- Startup commands
- Restart behavior

For example, a model-training profile can open terminals for Codex, a training script, TensorBoard, and a GPU monitor, each with its own directory and startup command.

## Startup commands

Startup commands are entered into the session shell after it starts. This supports workflows that require several interactive steps:

```text
ssh gpu-server
cd ~/projects/model
source .venv/bin/activate
tensorboard --logdir runs
```

Commands use the normal local shell, so SSH login, directory changes, virtual-environment activation, and interactive command-line tools follow the same input path as normal typing.

This makes it easy to prepare remote-development workflows, such as connecting to a GPU server, starting a training job, and opening monitoring tools across several sessions.

## Session management

Terminal sessions can be restarted when a process or SSH connection gets stuck. Dock-level startup commands can also prepare a complete multi-terminal workflow when a workspace opens.
