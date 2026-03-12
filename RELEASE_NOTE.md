# Release Notes: OpenClaw Extension v1.0.3

**Date**: March 9, 2026  
**Version**: 1.0.3

## Overview

This update keeps the extension documentation aligned with the current installer scope: MCP servers, skills, and the optional AINFT merchant MCP.

## Highlights

### 1. AINFT Skill Simplified

The current `ainft-skill` is intentionally reduced to local query functions:

- `check_balance.js`
- `check_orders.js`

The skill now:

- uses production by default
- manages the local AINFT API key
- does not include recharge execution logic

### 2. AINFT Merchant MCP Added to Installer

The installer now supports an optional remote MCP entry:

- server id: `ainft-merchant`
- endpoint: `https://ainft-agent.bankofai.io/mcp`

This keeps recharge tooling separate from the local AINFT query skill.

### 3. Documentation Scope Tightened

- Removed AINFT provider setup guidance from the extension docs
- Kept the docs focused on what `install.sh` manages directly
- Reduced overlap between component docs and environment-specific setup instructions

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

## Notes

- `install.sh` covers the OpenClaw Extension install flow for MCP servers and skills
- The local AINFT skill and the remote AINFT merchant MCP are separate components by design
