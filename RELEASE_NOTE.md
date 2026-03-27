# Release Notes: OpenClaw Extension v1.4.3

**Date**: March 28, 2026  
**Version**: 1.4.3

## Overview

This release restructures the installer around AgentWallet-first setup, adds a full clean-install flow, and pins core dependencies to stable versions for predictable deployments.

## Highlights

### 1. AgentWallet-First Setup
The installer now starts with AgentWallet initialization and routes CLI I/O through `/dev/tty` when available to support piped installs. It uses:
- `agent-wallet start --save-runtime-secrets` in normal mode
- `agent-wallet reset` + `agent-wallet start --override --save-runtime-secrets` in clean mode

### 2. Full Clean Install Mode
Clean install now performs a full cleanup before re-initialization:
- clears MCP entries in `~/.mcporter/mcporter.json`
- removes installed skills under `~/.openclaw/skills` and `.openclaw/skills`
- deletes local config files: `~/.x402-config.json` and `~/.mcporter/bankofai-config.json`
- requires explicit confirmation plus typing `CLEAN`

### 3. Pinned Defaults
The installer now pins:
- AgentWallet `2.3.0`
- Skills repository `v1.5.3`
- `mcp-server-tron@1.1.7`

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/tags/v1.4.3/install.sh | bash
```
