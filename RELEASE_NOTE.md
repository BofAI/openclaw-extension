# Release Notes: OpenClaw Extension v1.4.5

**Date**: March 30, 2026
**Version**: 1.4.5

## Overview

Bumps AgentWallet to stable `2.3.1` and the pinned skills repository tag to `v1.5.5`. Adds Windows installer support via `install.ps1` and `install.bat`.

## Changes

- Updated AgentWallet from `2.3.1-beta.0` to `2.3.1`
- Updated skills pin from `v1.5.4` to `v1.5.5`
- Added Windows installer (`install.ps1` + `install.bat` launcher)

## Pinned Defaults

- AgentWallet `2.3.1`
- Skills repository `v1.5.5`
- `mcp-server-tron@1.1.7`

## Installation

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/tags/v1.4.5/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/tags/v1.4.5/install.ps1 | iex
```
