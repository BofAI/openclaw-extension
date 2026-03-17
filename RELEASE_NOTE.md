# Release Notes: OpenClaw Extension v1.2.14

**Date**: March 15, 2026  
**Version**: 1.2.14

## Overview

This release pins the installer to a stable skills tag and aligns the extension with the current supported skill set.

## Highlights

### 1. Pinned Skills Tag
The installer now defaults to the `v1.4.12` tag of the [skills repository](https://github.com/BofAI/skills). This avoids unexpected changes from tracking the repository `main` branch and gives QA / ops a stable install target.

### 2. Updated Supported Skills
The installer flow and documentation now match the current supported skill set:
- `recharge-skill`
- `tronscan-skill`
- `sunswap`
- `x402-payment`

### 3. Improved Skill Setup Prompts
The installer now includes:
- local `BANKOFAI_API_KEY` setup guidance for `recharge-skill` for BANK OF AI accounts
- `TRONSCAN_API_KEY` setup guidance for `tronscan-skill`
- removal of legacy `8004-skill` prompts and references

## Installation Summary

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

## Configuration Notes
- You can still override the pinned skills tag by exporting `GITHUB_BRANCH` before running the installer.
- Re-running the installer will refresh the currently supported OpenClaw skills list and prompts.
