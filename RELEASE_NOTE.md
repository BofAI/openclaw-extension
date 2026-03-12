# Release Notes: OpenClaw Extension v1.1.0

**Date**: March 12, 2026  
**Version**: `1.1.0`

## Overview

This release adds Gasfree-related support while continuing to improve the public documentation structure for end users.

The key updates are:

- Gasfree API configuration support for `x402-payment`
- default skills branch updated to `v1.4.0`
- README reorganized into a clearer usage-first structure
- continued separation between local AINFT query skills and the remote AINFT merchant MCP

## Main Changes

### 1. Gasfree API Integration

`x402-payment` now supports gasless transactions on TRON through the Gasfree API.

The installer (`install.sh`) now supports:

- prompting for `GASFREE_API_KEY`
- prompting for `GASFREE_API_SECRET`
- writing credentials to `~/.x402-config.json`
- setting restricted permissions on that file

### 2. Updated Default Skills Version

The installer now supports skills branch selection through `GITHUB_BRANCH`.  
The default value is now:

```bash
GITHUB_BRANCH=v1.4.0
```

This keeps the extension aligned with the newer skills release by default.

### 3. README Refresh

The README has been reorganized into a more user-facing structure, covering:

- overview
- how the system works
- how to use skills
- compatible platforms
- installation
- security notes

## Installer Scope

The installer currently manages:

- `mcp-server-tron`
- `bnbchain-mcp`
- optional remote MCP: `ainft-merchant`
- skills installed from `https://github.com/BofAI/skills`

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

## Additional Configuration Notes

If you already installed `x402-payment`, you can re-run the installer to add or update:

- `GASFREE_API_KEY`
- `GASFREE_API_SECRET`

## Summary

This release is not a full installer rewrite. The main outcomes are:

- Gasfree support added
- default skills version aligned to `v1.4.0`
- documentation improved for end users
