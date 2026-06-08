# Security

## Claude Code configuration safety

This repository must not ship project-level Claude Code settings that execute commands automatically.

Do not commit `.claude/settings.json` hooks such as `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, or similar command hooks unless the command is small, readable, documented, and required for the plugin itself.

Do not commit obfuscated or generated executable payloads. Agent/plugin users may clone or install this repository into trusted workspaces, and project-level Claude settings can run automatically in those contexts.

If you need local automation while developing this repository, keep it untracked in `.claude/settings.local.json`.

## Reporting security issues

If you find config-injection behavior, hidden command execution, or obfuscated executable content in this repository, please open a security advisory or contact the maintainer privately before public disclosure when possible.
