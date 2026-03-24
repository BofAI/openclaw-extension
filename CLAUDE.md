# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OpenClaw Extension** is a bash-based installer that integrates blockchain access, wallet operations, and pre-built AI skills into the OpenClaw AI assistant platform. It is developed by BANK OF AI and enables AI agents to interact with TRON and BNB Chain blockchains.

## Development Commands

This is a pure bash project — there is no build step. The main artifact is `install.sh`.

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

## Architecture

### Single Entry Point

All logic lives in `install.sh` (~700 lines). There is no other application code.

### Installation Flow

The installer runs in phases:

1. **Mode selection** — Normal (preserve existing config) or Clean (wipe MCP/skills/config with explicit confirmation).
2. **AgentWallet setup** — Launches `agent-wallet` CLI (default v2.3.0) to provision a managed wallet. Clean mode uses `--override`.
3. **MCP server configuration** — Interactive multiselect; uses `npx add-mcp` to register servers with mcporter. Servers:
   - `@bankofai/mcp-server-tron@1.1.7` — TRON blockchain (pinned version)
   - `@bnb-chain/mcp@latest` — BNB Chain (uses raw `PRIVATE_KEY`, not AgentWallet-managed)
   - `bankofai-recharge` — Remote MCP at `https://recharge.bankofai.io/mcp`
4. **Skills installation** — Uses `npx skills add` to install skills from `BofAI/skills` GitHub repo. Prompts for global (user-level) or workspace-level scope.
   - Skills: `sunswap`, `tronscan-skill`, `x402-payment`, `recharge-skill`, `sunperp`

### Key Design Patterns

- **Interactive I/O via `/dev/tty`** — All prompts read from `/dev/tty` so the installer works correctly when piped from `curl`.
- **Node.js for JSON manipulation** — `node -e` one-liners handle JSON read/write (no Python dependency).
- **npx add-mcp** — Standard MCP server registration tool (`add-mcp@1.5.1`) targeting the mcporter agent.
- **npx skills add** — Standard skill installation tool (`skills@1.4.6`) from the Vercel Labs open agent skills ecosystem.
- **Multiselect UI** — Custom bash terminal UI with arrow-key navigation for selecting MCP servers and skills.

### Configuration Files (written by installer, not in this repo)

| File | Purpose |
|------|---------|
| `~/.mcporter/mcporter.json` | MCP server configurations |
| `~/.x402-config.json` | Gasfree API credentials (chmod 600) |
| `~/.mcporter/bankofai-config.json` | BANK OF AI config (removed in clean install) |
| `~/.openclaw/skills/` | User-level skills directory |
| `.openclaw/skills/` | Workspace-level skills directory |

### Prerequisites (installer enforces these)

- Node.js v18+
- Git
- OpenClaw (pre-installed)
- AgentWallet CLI v2.3.0

### Pinned Versions

| Component | Version |
|-----------|---------|
| AgentWallet | 2.3.0 |
| Skills repo | BofAI/skills (via npx skills add) |
| mcp-server-tron | 1.1.7 |
| add-mcp | 1.5.1 (via npx) |
| skills CLI | 1.4.6 (via npx) |

### bnbchain-mcp Note

`bnbchain-mcp` currently requires a raw `PRIVATE_KEY` env var and is **not** AgentWallet-compatible. This is a known limitation.

## Active Technologies
- Bash (POSIX-compatible with bashisms) + `add-mcp@1.5.1` (via npx), `skills@1.4.6` (via npx), Node.js v18+ (001-npx-skill-mcp-add)
- JSON config files (`~/.mcporter/mcporter.json`, `~/.x402-config.json`, `~/.mcporter/bankofai-config.json`) (001-npx-skill-mcp-add)

## Recent Changes
- 001-npx-skill-mcp-add: Added Bash (POSIX-compatible with bashisms) + `add-mcp@1.5.1` (via npx), `skills@1.4.6` (via npx), Node.js v18+
