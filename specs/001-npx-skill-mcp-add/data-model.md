# Data Model: Use npx skill/mcp add Commands

**Date**: 2026-03-24

## Configuration Files (unchanged structure, new write mechanism)

### mcporter.json (`~/.mcporter/mcporter.json`)

Written by `npx add-mcp` + Node.js env var injection (previously Python).

```json
{
  "mcpServers": {
    "mcp-server-tron": {
      "command": "npx",
      "args": ["-y", "@bankofai/mcp-server-tron@1.1.7"],
      "env": {
        "TRONGRID_API_KEY": "<value>"
      }
    },
    "bnbchain-mcp": {
      "command": "npx",
      "args": ["-y", "@bnb-chain/mcp@latest"],
      "env": {
        "PRIVATE_KEY": "<value>",
        "LOG_LEVEL": "INFO"
      }
    },
    "bankofai-recharge": {
      "baseUrl": "https://recharge.bankofai.io/mcp"
    }
  }
}
```

### bankofai-config.json (`~/.mcporter/bankofai-config.json`)

Written by Node.js one-liner (previously Python). Used by recharge-skill.

```json
{
  "api_key": "<BANKOFAI_API_KEY>",
  "base_url": "https://chat.ainft.com"
}
```

### x402-config.json (`~/.x402-config.json`)

Written by Node.js one-liner (previously Python). Used by x402-payment skill.

```json
{
  "gasfree_api_key": "<GASFREE_API_KEY>",
  "gasfree_api_secret": "<GASFREE_API_SECRET>"
}
```

## Skills (installed via `npx skills add`)

| Skill ID | Source | Post-install Config | Config File |
|----------|--------|-------------------|-------------|
| sunswap | BofAI/skills | None | — |
| tronscan-skill | BofAI/skills | TRONSCAN_API_KEY env var guidance | Shell profile |
| x402-payment | BofAI/skills | Gasfree API key/secret prompt | ~/.x402-config.json |
| recharge-skill | BofAI/skills | BANKOFAI_API_KEY prompt | ~/.mcporter/bankofai-config.json |
| sunperp | BofAI/skills | TRON_PRIVATE_KEY guidance | Shell profile |

## State Transitions

### Installation Modes

```
Start → Mode Selection
  ├─ Normal Install → AgentWallet (preserve) → MCP add → Skills add → Config prompts → Done
  └─ Clean Install → Confirm → Clear MCP → Clear Skills → Clear configs
                   → AgentWallet (override) → MCP add → Skills add → Config prompts → Done
```

## Removed Entities

- `write_server_config()` Python function — replaced by `npx add-mcp`
- `clear_all_mcp_entries()` Python function — replaced by Node.js one-liner
- `json_string_or_null()` Python helper — replaced by Node.js
- `clone_skills_repo()` — replaced by `npx skills add`
- `copy_skill()` — replaced by `npx skills add`
- `select_install_target()` — simplified to global vs project-level flag
- `PYTHON_CMD` variable and Python 3 check — no longer needed
- `TEMP_DIR` and temp file management for git clone — no longer needed
