# AINFT Integration Guide

This guide reflects the current AINFT integration flow in this repository.

## Scope

There are two separate AINFT integration surfaces:

1. **AINFT model provider**
   - Configured by `setup_ainft.sh`
   - Writes the AINFT provider into `~/.openclaw/openclaw.json`
   - Stores the local AINFT API key in `~/.ainft/config.json`

2. **AINFT local skill**
   - Installed as `ainft-skill`
   - Supports local balance and order queries only
   - Does not execute recharge or payment flows

## Production Only

The current setup script is fixed to **production**.

- Web: `https://chat.ainft.com`
- API base URL: `https://chat.ainft.com/webapi/`
- OpenAI-compatible chat endpoint: `https://chat.ainft.com/webapi/chat/completions`

## Quick Setup

Run:

```bash
bash setup_ainft.sh
```

What the script does:

1. Validates that `~/.openclaw/openclaw.json` already exists
2. Checks that `Node.js >= 22` and `python3` are available
3. Prompts for an AINFT API key
4. Validates the key against the production chat completions endpoint
5. Fetches the live model list from `config.getGlobalConfig`
6. Writes local AINFT config to `~/.ainft/config.json`
7. Writes the AINFT provider to `~/.openclaw/openclaw.json`
8. Updates `agents.defaults.model.primary`
9. Updates `agents.list.main.model` only if `main` already exists
10. Restarts the OpenClaw gateway

## Local AINFT Config

The local skill config written by `setup_ainft.sh` is minimal:

```json
{
  "api_key": "YOUR_AINFT_API_KEY",
  "base_url": "https://chat.ainft.com",
  "timeout_ms": 15000
}
```

This file lives at:

```bash
~/.ainft/config.json
```

## OpenClaw Provider Config

The provider written into `~/.openclaw/openclaw.json` uses:

- `api = openai-completions`
- `baseUrl = https://chat.ainft.com/webapi/`
- a dynamic model list fetched from AINFT production

If you choose to set AINFT as the default model provider, the script updates:

- `agents.defaults.model.primary`
- `agents.list.main.model` only when `main` is already materialized in config

If `agents.list.main` does not exist, the script does **not** create it.

## Manual Validation

After setup, test with:

```bash
openclaw agent --agent main --message "你好"
```

If you want to force a specific AINFT model first:

```bash
openclaw models set ainft/gpt-5-nano
openclaw agent --agent main --message "你好"
```

## AINFT Skill

The current `ainft-skill` is intentionally small.

Supported local scripts:

```bash
node ~/.openclaw/skills/ainft-skill/scripts/check_balance.js --format json
node ~/.openclaw/skills/ainft-skill/scripts/check_orders.js --format json
```

Current scope:

- balance query
- order query

Out of scope:

- recharge
- merchant settlement
- native TRX / BNB transfer flows

## AINFT Merchant MCP

If you also want remote AINFT recharge tools, install the MCP entry through `install.sh`.

Current remote endpoint:

```text
https://ainft-agent.bankofai.io/mcp
```

Installed `mcporter` server id:

```text
ainft-merchant
```

## Troubleshooting

### `401 status code`

- The API key is invalid, malformed, or expired
- Re-run `setup_ainft.sh` and enter a single valid key

### `404 status code`

- The request is hitting the wrong endpoint or provider path
- Re-run `setup_ainft.sh` so `baseUrl` is rewritten to the current production value

### Default model did not change

Check both of these fields in `~/.openclaw/openclaw.json`:

- `agents.defaults.model.primary`
- `agents.list.main.model`

If `agents.list.main.model` exists, it overrides the default model for `main`.

## References

- OpenClaw Extension README: `README.md`
- AINFT setup script: `setup_ainft.sh`
- AINFT skill: `../skills/ainft-skill/SKILL.md`
