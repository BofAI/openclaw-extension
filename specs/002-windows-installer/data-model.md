# Data Model: Windows Installer

This feature does not introduce new data entities. The installer produces the same configuration files as `install.sh`. This document maps the cross-OS file paths and structures.

## Configuration File Mapping

| File (Linux/macOS) | File (Windows) | Purpose |
|---------------------|----------------|---------|
| `~/.mcporter/mcporter.json` | `%USERPROFILE%\.mcporter\mcporter.json` | MCP server configurations |
| `~/.x402-config.json` | `%USERPROFILE%\.x402-config.json` | Gasfree API credentials |
| `~/.mcporter/bankofai-config.json` | `%USERPROFILE%\.mcporter\bankofai-config.json` | BANK OF AI config |
| `~/.openclaw/skills/` | `%USERPROFILE%\.openclaw\skills\` | User-level skills |
| `.openclaw/skills/` | `.openclaw\skills\` | Workspace-level skills |

## JSON Structures

All JSON structures are identical across platforms. The `node -e` one-liners produce the same output regardless of OS since Node.js is cross-platform.

### mcporter.json

```json
{
  "mcpServers": {
    "<server-id>": {
      "env": {
        "<ENV_VAR>": "<value>"
      }
    }
  }
}
```

### x402-config.json

```json
{
  "gasfree_api_key": "<key>",
  "gasfree_api_secret": "<secret>"
}
```

### bankofai-config.json

```json
{
  "api_key": "<key>",
  "base_url": "https://chat.ainft.com"
}
```

## Permission Model Mapping

| Unix | Windows Equivalent | Implementation |
|------|-------------------|----------------|
| `chmod 600` (owner rw) | Owner-only ACL | `icacls` to remove inheritance + remove group access + grant current user RW |

## State Transitions

The installer has the same state machine on both platforms:

```
Start → Mode Selection → [Clean Mode cleanup if selected] → AgentWallet Setup → MCP Server Selection → MCP Configuration → Skills Scope Selection → Skills Installation → Post-Install Config → Summary
```

No new states or transitions are introduced for Windows.
