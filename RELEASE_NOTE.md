# Release Notes: OpenClaw Extension v1.0.3

**Date**: March 9, 2026  
**Version**: 1.0.3

## Overview

This update aligns the extension with the current AINFT integration model and the current OpenClaw configuration behavior.

## Highlights

### 1. AINFT Setup Updated

- `setup_ainft.sh` is now aligned to the current production flow
- Production only:
  - `https://chat.ainft.com`
  - `https://chat.ainft.com/webapi/`
- API key validation uses the live OpenAI-compatible endpoint:
  - `/webapi/chat/completions`
- The script fetches the live model list from AINFT instead of relying on a fixed local model table

### 2. OpenClaw Config Behavior Clarified

- The setup flow updates `agents.defaults.model.primary`
- If `agents.list.main.model` already exists, it is also updated
- If `agents.list.main` does not exist, the script does not force-create it
- This avoids the earlier mismatch where `main` could silently override the configured default model

### 3. AINFT Skill Simplified

The current `ainft-skill` is intentionally reduced to local query functions:

- `check_balance.js`
- `check_orders.js`

The skill now:

- uses production by default
- manages the local AINFT API key
- does not include recharge execution logic

### 4. AINFT Merchant MCP Added to Installer

The installer now supports an optional remote MCP entry:

- server id: `ainft-merchant`
- endpoint: `https://ainft-agent.bankofai.io/mcp`

This keeps recharge tooling separate from the local AINFT query skill.

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

Optional AINFT provider setup:

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/main/setup_ainft.sh | bash
```

## Notes

- `install.sh` still supports the broader OpenClaw Extension install flow for MCP servers and skills
- `setup_ainft.sh` specifically configures AINFT as a model provider in OpenClaw
- The local AINFT skill and the remote AINFT merchant MCP are separate components by design
