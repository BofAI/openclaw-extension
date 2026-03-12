# Contributing

## Development Scope

This repository mainly contains:

- `install.sh` for installation and configuration
- public-facing documentation
- release notes and changelog content

Keep changes focused. Do not mix unrelated installer, documentation, and credential-flow changes in one PR unless they are tightly coupled.

## Before Opening a Pull Request

- test the installer flow you changed
- update `README.md` when user-facing behavior changes
- update `CHANGELOG.md` for notable changes
- update `RELEASE_NOTE.md` when the release narrative changes

For shell changes, prefer validating with:

```bash
bash -n install.sh
```

If you modify install prompts or credential storage behavior, document:

- what file is written
- what environment variable is read
- what the expected file permissions are

## Pull Request Checklist

- explain what changed
- explain why it changed
- include test steps
- mention whether the change affects:
  - MCP server installation
  - skills installation
  - AINFT merchant setup
  - Gasfree setup

## Credentials

Never include real private keys, API secrets, JWTs, or local config dumps in commits, screenshots, logs, or PR descriptions.
