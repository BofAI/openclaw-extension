# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OpenClaw Extension** is a cross-platform installer that integrates blockchain access, wallet operations, and pre-built AI skills into the OpenClaw AI assistant platform. It is developed by BANK OF AI and enables AI agents to interact with TRON and BNB Chain blockchains. The installer is available as `install.sh` (Linux/macOS) and `install.ps1` + `install.bat` (Windows).

## Development Commands

This is a pure shell project — there is no build step. The main artifacts are `install.sh` (Linux/macOS) and `install.ps1` (Windows).

### Linux/macOS

```bash
# Test the installer locally
./install.sh

# Test that the script is valid bash syntax
bash -n install.sh

# Test in a pipe-install scenario (like the curl | bash flow)
cat install.sh | bash
```

Lint check:
```bash
shellcheck install.sh
```

### Windows

```powershell
# Test the installer locally (via batch launcher)
.\install.bat

# Or directly via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1

# Test that the script is valid PowerShell syntax
[System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$null, [ref]$null)

# Test in a pipe-install scenario (like the irm | iex flow)
Get-Content install.ps1 -Raw | Invoke-Expression
```

## Architecture

### Single Entry Point (Per OS)

- **Linux/macOS**: All logic lives in `install.sh` (~700 lines).
- **Windows**: All logic lives in `install.ps1` (~700 lines). `install.bat` is a thin cmd.exe launcher (~6 lines) that invokes `install.ps1` with `-NoProfile -ExecutionPolicy Bypass`.

### Installation Flow

The installer runs in phases:

1. **Mode selection** — Normal (preserve existing config) or Clean (wipe MCP/skills/config with explicit confirmation).
2. **AgentWallet setup** — Launches `agent-wallet` CLI (default v2.3.1) to provision a managed wallet. Clean mode uses `--override`.
3. **MCP server configuration** — Interactive multiselect; uses `npx add-mcp` to register servers with mcporter. Servers:
   - `@bankofai/mcp-server-tron@1.1.7` — TRON blockchain (pinned version)
   - `@bnb-chain/mcp@latest` — BNB Chain (uses raw `PRIVATE_KEY`, not AgentWallet-managed)
   - `bankofai-recharge` — Remote MCP at `https://recharge.bankofai.io/mcp`
4. **Skills installation** — Uses `npx skills add` to install skills from `BofAI/skills` GitHub repo. Prompts for global (user-level) or workspace-level scope.
   - Skills: `sunswap`, `tronscan-skill`, `x402-payment`, `recharge-skill`, `sunperp`

### Key Design Patterns

- **Interactive I/O via `/dev/tty` (bash) / `Read-Host` (PowerShell)** — All prompts read from the console so the installer works correctly when piped.
- **Node.js for JSON manipulation** — `node -e` one-liners handle JSON read/write (no Python dependency). The same JavaScript code is used on both platforms.
- **npx add-mcp** — Standard MCP server registration tool (`add-mcp@1.5.1`) targeting the mcporter agent.
- **npx skills add** — Standard skill installation tool (`skills@1.4.6`) from the Vercel Labs open agent skills ecosystem.
- **Multiselect UI** — Custom terminal UI with arrow-key navigation for selecting MCP servers and skills (bash `read` / PowerShell `[Console]::ReadKey()`).
- **Credential security** — `chmod 600` on Linux/macOS, `icacls` owner-only ACL on Windows.

### Configuration Files (written by installer, not in this repo)

| File (Linux/macOS) | File (Windows) | Purpose |
|--------------------|----------------|---------|
| `~/.mcporter/mcporter.json` | `%USERPROFILE%\.mcporter\mcporter.json` | MCP server configurations |
| `~/.x402-config.json` | `%USERPROFILE%\.x402-config.json` | Gasfree API credentials (restricted perms) |
| `~/.mcporter/bankofai-config.json` | `%USERPROFILE%\.mcporter\bankofai-config.json` | BANK OF AI config (removed in clean install) |
| `~/.openclaw/skills/` | `%USERPROFILE%\.openclaw\skills\` | User-level skills directory |
| `.openclaw/skills/` | `.openclaw\skills\` | Workspace-level skills directory |

### Prerequisites (installer enforces these)

- Node.js v18+
- Git
- OpenClaw (pre-installed)
- AgentWallet CLI v2.3.1
- **Windows only**: PowerShell 5.1+ (included with Windows 10/11), Windows 10 build 1511+ for ANSI color support

### Pinned Versions

| Component | Version |
|-----------|---------|
| AgentWallet | 2.3.1 |
| Skills repo | BofAI/skills (via npx skills add) |
| mcp-server-tron | 1.1.7 |
| add-mcp | 1.5.1 (via npx) |
| skills CLI | 1.4.6 (via npx) |

### bnbchain-mcp Note

`bnbchain-mcp` currently requires a raw `PRIVATE_KEY` env var and is **not** AgentWallet-compatible. This is a known limitation.

## Active Technologies
- Bash (POSIX-compatible with bashisms) + `add-mcp@1.5.1` (via npx), `skills@1.4.6` (via npx), Node.js v18+ (001-npx-skill-mcp-add)
- JSON config files (`~/.mcporter/mcporter.json`, `~/.x402-config.json`, `~/.mcporter/bankofai-config.json`) (001-npx-skill-mcp-add)
- PowerShell 5.1+ (ships with Windows 10/11), cmd batch for launcher + Node.js v18+ (npx), Git, AgentWallet CLI v2.3.1, add-mcp@1.5.1, skills@1.4.6 (002-windows-installer)
- JSON config files in `%USERPROFILE%\.mcporter\` and `%USERPROFILE%\` (002-windows-installer)

## Recent Changes
- 001-npx-skill-mcp-add: Added Bash (POSIX-compatible with bashisms) + `add-mcp@1.5.1` (via npx), `skills@1.4.6` (via npx), Node.js v18+
