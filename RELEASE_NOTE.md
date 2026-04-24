# Release Notes: OpenClaw Extension v1.4.6

**Date**: April 2, 2026
**Version**: 1.4.6

## Overview

Pins the installer to the latest published `skills` release tag, `v1.5.8`, so the extension follows the current shipped skill set instead of an unversioned branch. The release also simplifies the installation flow by removing interactive prompts for TRONGRID API key, Gasfree API credentials, and sunperp private key notice.

## Changes

- Updated the default skills source to the published release tag `skills@v1.5.8`
- Updated the documented default skill set to match `skills@v1.5.8`
- Removed TRONGRID API key prompt from TRON MCP server installation
- Removed Gasfree API credentials prompt from x402-payment skill setup
- Removed sunperp `TRON_PRIVATE_KEY` dependency notice
- Clarified TRON MCP install messaging

## Pinned Defaults

- AgentWallet `2.3.1`
- Skills repository `v1.5.8`
- `mcp-server-tron@1.1.7`

## Installation

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/tags/v1.4.6/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/tags/v1.4.6/install.ps1 | iex
```
