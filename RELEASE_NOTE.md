# Release Notes: OpenClaw Extension v1.1.0

**Date**: March 12, 2026  
**Version**: 1.1.0

## Overview

This release introduces native support for gasless transactions via the Gasfree API and updates the extension to use the latest version of AI agent skills.

## Highlights

### 1. Gasfree API Integration
The `x402-payment` skill now supports gasless transactions on the TRON network. The installer (`install.sh`) has been enhanced to:
- Prompt for `GASFREE_API_KEY` and `GASFREE_API_SECRET` during setup.
- Securely store credentials in `~/.x402-config.json` with restricted file permissions (`600`).

### 2. Updated Skills Repository (v1.4.0)
The extension now defaults to the `v1.4.0` branch of the [skills repository](https://github.com/BofAI/skills), ensuring compatibility with the latest protocol updates and bug fixes.

### 3. Improved AINFT Merchant Setup
Multiple fixes have been applied to the AINFT setup process, ensuring a smoother experience when configuring the optional `ainft-merchant` MCP server.

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

## Configuration Notes
- If you have already installed the `x402-payment` skill, you can re-run the installer to configure Gasfree credentials.
- The `v1.4.0` skills branch is now required for full feature support.
