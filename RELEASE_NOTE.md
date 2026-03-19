# Release Notes: OpenClaw Extension v1.3.0

**Date**: March 19, 2026  
**Version**: 1.3.0

## Overview

This release adds Agent Wallet integration to the installer and updates the extension workflow around wallet configuration for `x402-payment` and `mcp-server-tron`.

## Highlights

### 1. Agent Wallet Integration
The installer now supports Agent Wallet as part of the main setup flow. This improves the wallet management experience for `x402-payment` and `mcp-server-tron` and makes the overall configuration process more consistent.

### 2. Updated Credential Flow
Credential configuration has been updated around Agent Wallet support, while keeping environment-variable and config-based setup paths available for compatible components.

### 3. Documentation Refresh
Project documentation has been updated to reflect the new wallet configuration flow, and unused mnemonic-related guidance has been removed.

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

## Configuration Notes
- The installer now defaults to the `dev/agent_wallet_0317` branch of the [skills repository](https://github.com/BofAI/skills).
- You can still override the skills source by exporting `GITHUB_BRANCH` before running the installer.
- Re-running the installer will refresh the wallet setup flow and related prompts.
